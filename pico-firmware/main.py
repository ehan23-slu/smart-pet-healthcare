import machine
import bluetooth
from time import sleep
from math import sqrt


# =========================================================
# SETTINGS
# =========================================================

DEBUG = False

MAX30102_ADDRESS = 0x57
MAX30205_ADDRESS = 0x48

# MAX30102 is configured for:
# 100 samples/sec with 4-sample FIFO averaging
# -> effective FIFO output rate = about 25 samples/sec
SAMPLE_RATE = 25

# About 8 seconds of PPG data
BUFFER_SIZE = 200

# Recalculate about once per second
UPDATE_EVERY = 25

# Based on our observed values:
# no finger ~ hundreds
# finger ~ tens/hundreds of thousands
FINGER_THRESHOLD = 10000


# =========================================================
# I2C BUSES
# =========================================================

# MAX30102
# GP16 = SDA
# GP17 = SCL
ppg = machine.I2C(
    0,
    sda=machine.Pin(16),
    scl=machine.Pin(17),
    freq=10000
)

# MAX30205
# GP18 = SDA
# GP19 = SCL
temp = machine.I2C(
    1,
    sda=machine.Pin(18),
    scl=machine.Pin(19),
    freq=10000
)


# =========================================================
# CHECK BOTH SENSORS
# =========================================================

ppg_devices = ppg.scan()
temp_devices = temp.scan()

print("PPG bus:", [hex(x) for x in ppg_devices])
print("Temperature bus:", [hex(x) for x in temp_devices])

if MAX30102_ADDRESS not in ppg_devices:
    raise Exception("MAX30102 not found!")

if MAX30205_ADDRESS not in temp_devices:
    raise Exception("MAX30205 not found!")

print("Both sensors detected!")
print()


# =========================================================
# MAX30102 FUNCTIONS
# =========================================================

def write_ppg_register(register, value):
    """
    Write one value to one MAX30102 register.
    We use writeto() because this method worked reliably
    with our MAX30102.
    """
    ppg.writeto(
        MAX30102_ADDRESS,
        bytes([register, value])
    )

    sleep(0.05)


def setup_max30102():

    # Clear FIFO
    write_ppg_register(0x04, 0x00)
    write_ppg_register(0x05, 0x00)
    write_ppg_register(0x06, 0x00)

    # FIFO configuration
    # 4-sample averaging
    # FIFO rollover enabled
    write_ppg_register(0x08, 0x5F)

    # SpO2 configuration
    # 100 samples/sec
    # 18-bit ADC
    write_ppg_register(0x0A, 0x27)

    # Red LED power
    write_ppg_register(0x0C, 0x24)

    # IR LED power
    write_ppg_register(0x0D, 0x24)

    # SpO2 mode
    # Red + IR
    write_ppg_register(0x09, 0x03)

    print("MAX30102 started")


# =========================================================
# MAX30205 TEMPERATURE
# =========================================================

def read_temperature():

    # Temperature register = 0x00
    # Read two bytes
    data = temp.readfrom_mem(
        MAX30205_ADDRESS,
        0x00,
        2
    )

    raw = (data[0] << 8) | data[1]

    # Convert unsigned 16-bit value
    # to signed two's-complement value
    if raw & 0x8000:
        raw -= 65536

    # MAX30205:
    # 1 LSB = 0.00390625 degree C
    temperature_c = raw * 0.00390625

    return temperature_c


# =========================================================
# HELPER: MEDIAN
# =========================================================

def median(values):

    if len(values) == 0:
        return None

    ordered = sorted(values)

    middle = len(ordered) // 2

    if len(ordered) % 2 == 1:
        return ordered[middle]

    return (
        ordered[middle - 1]
        + ordered[middle]
    ) / 2


# =========================================================
# HEART RATE
# =========================================================

def calculate_heart_rate(ir_values):

    if len(ir_values) < BUFFER_SIZE:
        return None

    # -----------------------------------------
    # 1. Smooth signal with moving average
    # -----------------------------------------

    smooth = []

    window = 4

    for i in range(len(ir_values) - window + 1):

        total = 0

        for j in range(window):
            total += ir_values[i + j]

        smooth.append(total / window)


    # -----------------------------------------
    # 2. Remove DC baseline
    # -----------------------------------------

    mean_ir = sum(smooth) / len(smooth)

    signal = []

    for value in smooth:
        signal.append(value - mean_ir)


    # Sometimes pulse appears as a downward
    # valley instead of an upward peak.
    positive_amplitude = max(signal)
    negative_amplitude = abs(min(signal))

    if negative_amplitude > positive_amplitude:
        signal = [-x for x in signal]


    # -----------------------------------------
    # 3. Dynamic peak threshold
    # -----------------------------------------

    amplitude = max(signal)

    if amplitude <= 0:
        return None

    threshold = amplitude * 0.35


    # -----------------------------------------
    # 4. Find pulse peaks
    # -----------------------------------------

    peaks = []

    # At 25 Hz:
    # 8 samples ~= maximum ~187 BPM
    min_peak_distance = 8

    for i in range(1, len(signal) - 1):

        is_peak = (
            signal[i] > threshold
            and signal[i] > signal[i - 1]
            and signal[i] >= signal[i + 1]
        )

        if is_peak:

            if len(peaks) == 0:
                peaks.append(i)

            elif i - peaks[-1] >= min_peak_distance:
                peaks.append(i)


    if len(peaks) < 3:
        return None


    # -----------------------------------------
    # 5. Calculate intervals between beats
    # -----------------------------------------

    intervals = []

    for i in range(1, len(peaks)):

        interval = peaks[i] - peaks[i - 1]

        bpm_for_interval = (
            60 * SAMPLE_RATE / interval
        )

        # Human-finger demo range.
        # This range should NOT be used later
        # as an animal physiological range.
        if 40 <= bpm_for_interval <= 180:
            intervals.append(interval)


    if len(intervals) < 2:
        return None


    # Median is less sensitive to one false peak
    beat_interval = median(intervals)

    bpm = (
        60 * SAMPLE_RATE
        / beat_interval
    )

    if bpm < 40 or bpm > 180:
        return None

    return bpm


# =========================================================
# SpO2
# =========================================================

def calculate_spo2(red_values, ir_values):

    if len(red_values) < BUFFER_SIZE:
        return None


    # -----------------------------------------
    # DC components
    # -----------------------------------------

    dc_red = sum(red_values) / len(red_values)
    dc_ir = sum(ir_values) / len(ir_values)

    if dc_red < FINGER_THRESHOLD:
        return None

    if dc_ir < FINGER_THRESHOLD:
        return None


    # -----------------------------------------
    # AC components
    # RMS variation around DC
    # -----------------------------------------

    red_variance = 0
    ir_variance = 0

    for value in red_values:
        red_variance += (
            value - dc_red
        ) ** 2

    for value in ir_values:
        ir_variance += (
            value - dc_ir
        ) ** 2


    ac_red = sqrt(
        red_variance / len(red_values)
    )

    ac_ir = sqrt(
        ir_variance / len(ir_values)
    )


    if ac_ir == 0:
        return None


    # -----------------------------------------
    # Ratio of ratios
    #
    #       AC_red / DC_red
    # R = -------------------
    #       AC_ir / DC_ir
    # -----------------------------------------

    R = (
        (ac_red / dc_red)
        /
        (ac_ir / dc_ir)
    )


    # Reject clearly unreasonable ratios
    if R <= 0 or R > 2:
        return None


    # Preliminary empirical SpO2 approximation
    spo2 = (
        -45.060 * R * R
        + 30.354 * R
        + 94.845
    )


    if spo2 < 70 or spo2 > 100:
        return None

    return spo2


# =========================================================
# INITIALIZE SENSOR
# =========================================================

setup_max30102()

print()
print("Place your finger on the MAX30102.")
print("Keep your finger still.")
print()


# =========================================================
# BUFFERS
# =========================================================

red_buffer = []
ir_buffer = []

samples_since_update = 0

finger_present = False

hr_history = []
spo2_history = []


# =========================================================
# BLUETOOTH LOW ENERGY (BLE) - 3 VITAL SIGNS
# =========================================================
# All three characteristics are part of a single Pet Health Service.
# Characteristic payloads are UTF-8 text such as b"83.3" or b"measuring".
ble = bluetooth.BLE()
ble.active(True)
ble.gap_advertise(None)

SERVICE_UUID = bluetooth.UUID("12345678-1234-5678-1234-56789abcdef0")
HEART_RATE_UUID = bluetooth.UUID("12345678-1234-5678-1234-56789abcdef1")
SPO2_UUID = bluetooth.UUID("12345678-1234-5678-1234-56789abcdef2")
TEMPERATURE_UUID = bluetooth.UUID("12345678-1234-5678-1234-56789abcdef3")

value_flags = bluetooth.FLAG_READ | bluetooth.FLAG_NOTIFY
pet_health_service = (
    SERVICE_UUID,
    (
        (HEART_RATE_UUID, value_flags),
        (SPO2_UUID, value_flags),
        (TEMPERATURE_UUID, value_flags),
    ),
)
((heart_rate_handle, spo2_handle, temperature_handle),) = (
    ble.gatts_register_services((pet_health_service,))
)

# Initial values are intentionally not presented as actual measurements.
ble.gatts_write(heart_rate_handle, b"measuring")
ble.gatts_write(spo2_handle, b"measuring")
ble.gatts_write(temperature_handle, b"measuring")

name = "PetHealthMonitor"
name_bytes = name.encode("utf-8")
advertising_data = (
    bytes([2, 0x01, 0x06])
    + bytes([len(name_bytes) + 1, 0x09])
    + name_bytes
)

_IRQ_CENTRAL_CONNECT = 1
_IRQ_CENTRAL_DISCONNECT = 2
connections = set()

def ble_irq(event, data):
    if event == _IRQ_CENTRAL_CONNECT:
        conn_handle, _, _ = data
        connections.add(conn_handle)
    elif event == _IRQ_CENTRAL_DISCONNECT:
        conn_handle, _, _ = data
        connections.discard(conn_handle)
        ble.gap_advertise(100_000, adv_data=advertising_data)

ble.irq(ble_irq)
ble.gap_advertise(100_000, adv_data=advertising_data)
print("BLE advertising as:", name)


def publish_value(handle, value, digits=1):
    if value is None:
        payload = b"measuring"
    elif digits == 2:
        payload = ("{:.2f}".format(value)).encode("utf-8")
    else:
        payload = ("{:.1f}".format(value)).encode("utf-8")

    # Store the current value for clients that perform a manual Read.
    ble.gatts_write(handle, payload)

    # Push updates to connected clients that subscribed to notifications.
    for conn_handle in tuple(connections):
        try:
            ble.gatts_notify(conn_handle, handle)
        except OSError:
            pass


def publish_heart_rate(value):
    publish_value(heart_rate_handle, value, digits=1)


def publish_spo2(value):
    publish_value(spo2_handle, value, digits=1)


def publish_temperature(value):
    publish_value(temperature_handle, value, digits=2)


def publish_measurements(hr_value, spo2_value, temp_value):
    publish_heart_rate(hr_value)
    publish_spo2(spo2_value)
    publish_temperature(temp_value)


# =========================================================
# =========================================================
# MAIN LOOP
# =========================================================

while True:

    # Read FIFO pointers
    write_pointer = ppg.readfrom_mem(
        MAX30102_ADDRESS,
        0x04,
        1
    )[0]

    read_pointer = ppg.readfrom_mem(
        MAX30102_ADDRESS,
        0x06,
        1
    )[0]


    available = (
        write_pointer - read_pointer
    ) & 0x1F


    while available > 0:

        # One sample:
        # 3 bytes Red
        # 3 bytes IR
        data = ppg.readfrom_mem(
            MAX30102_ADDRESS,
            0x07,
            6
        )


        red = (
            (data[0] << 16)
            | (data[1] << 8)
            | data[2]
        ) & 0x3FFFF


        ir = (
            (data[3] << 16)
            | (data[4] << 8)
            | data[5]
        ) & 0x3FFFF


        if DEBUG:
            print(
                "Raw Red:",
                red,
                "| Raw IR:",
                ir
            )


        # =================================================
        # Finger detection
        # =================================================

        if ir < FINGER_THRESHOLD:

            if finger_present:
                print()
                print("Finger removed.")
                print("Place finger on sensor...")
                print()

            finger_present = False
            publish_heart_rate(None)
            publish_spo2(None)

            red_buffer = []
            ir_buffer = []

            samples_since_update = 0

            hr_history = []
            spo2_history = []

            available -= 1
            continue


        # Finger has just been placed
        if not finger_present:

            finger_present = True

            red_buffer = []
            ir_buffer = []

            samples_since_update = 0

            print()
            print("Finger detected!")
            print("Collecting PPG data...")
            print()


        # =================================================
        # Store samples
        # =================================================

        red_buffer.append(red)
        ir_buffer.append(ir)

        samples_since_update += 1


        # Keep only most recent 8 seconds
        if len(red_buffer) > BUFFER_SIZE:
            red_buffer.pop(0)

        if len(ir_buffer) > BUFFER_SIZE:
            ir_buffer.pop(0)


        # =================================================
        # While collecting initial data
        # =================================================

        if (
            len(ir_buffer) < BUFFER_SIZE
            and samples_since_update % SAMPLE_RATE == 0
        ):

            temperature = read_temperature()

            publish_temperature(temperature)

            seconds_collected = (
                len(ir_buffer) / SAMPLE_RATE
            )

            print("---------------------------")
            print(
                "Temperature:",
                round(temperature, 2),
                "C"
            )

            print(
                "Heart Rate: measuring...",
                round(seconds_collected, 1),
                "/ 8 sec"
            )

            print(
                "SpO2: measuring..."
            )


        # =================================================
        # Calculate HR and SpO2
        # =================================================

        if (
            len(ir_buffer) >= BUFFER_SIZE
            and samples_since_update >= UPDATE_EVERY
        ):

            samples_since_update = 0

            temperature = read_temperature()

            hr = calculate_heart_rate(
                ir_buffer
            )

            spo2 = calculate_spo2(
                red_buffer,
                ir_buffer
            )


            # ---------------------------------------------
            # Smooth HR output over recent measurements
            # ---------------------------------------------

            if hr is not None:

                hr_history.append(hr)

                if len(hr_history) > 5:
                    hr_history.pop(0)

                hr_display = median(hr_history)

            else:
                hr_display = None


            # ---------------------------------------------
            # Smooth SpO2 output
            # ---------------------------------------------

            if spo2 is not None:

                spo2_history.append(spo2)

                if len(spo2_history) > 5:
                    spo2_history.pop(0)

                spo2_display = median(
                    spo2_history
                )

            else:
                spo2_display = None


            # ---------------------------------------------
            # Human-readable output
            # ---------------------------------------------

            print()
            print("===========================")

            print(
                "Temperature:",
                round(temperature, 2),
                "C"
            )

            if hr_display is not None:

                print(
                    "Heart Rate:",
                    round(hr_display, 1),
                    "BPM"
                )

            else:
                print(
                    "Heart Rate: measuring..."
                )


            if spo2_display is not None:

                print(
                    "SpO2:",
                    round(spo2_display, 1),
                    "%"
                )

            else:
                print(
                    "SpO2: measuring..."
                )


            print("===========================")

            # Publish the three measurements computed above.
            publish_measurements(hr_display, spo2_display, temperature)


        available -= 1


    sleep(0.02)