import Foundation
import Combine
import CoreBluetooth

final class BluetoothManager: NSObject, ObservableObject {

    // Values displayed in SwiftUI
    @Published private(set) var status = "Starting Bluetooth..."
    @Published private(set) var heartRate: Double?
    @Published private(set) var spo2: Double?
    @Published private(set) var temperature: Double?

    private var central: CBCentralManager!
    private var pico: CBPeripheral?

    // Same UUIDs used in MicroPython
    private let serviceUUID = CBUUID(
        string: "12345678-1234-5678-1234-56789abcdef0"
    )

    private let heartRateUUID = CBUUID(
        string: "12345678-1234-5678-1234-56789abcdef1"
    )

    private let spo2UUID = CBUUID(
        string: "12345678-1234-5678-1234-56789abcdef2"
    )

    private let temperatureUUID = CBUUID(
        string: "12345678-1234-5678-1234-56789abcdef3"
    )

    override init() {
        super.init()

        central = CBCentralManager(
            delegate: self,
            queue: nil
        )
    }

    private func startScanning() {
        guard central.state == .poweredOn else { return }

        status = "Searching for PetHealthMonitor..."

        central.scanForPeripherals(
            withServices: nil,
            options: nil
        )
    }
}

// MARK: - Bluetooth Connection

extension BluetoothManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(
        _ central: CBCentralManager
    ) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            status = "Bluetooth not available: \(central.state.rawValue)"
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = advertisementData[CBAdvertisementDataLocalNameKey]
            as? String ?? peripheral.name ?? ""

        guard name == "PetHealthMonitor" else { return }

        central.stopScan()

        pico = peripheral
        peripheral.delegate = self

        status = "Connecting..."

        central.connect(peripheral, options: nil)
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        status = "Connected; discovering service..."

        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        status = "Connection failed: \(error?.localizedDescription ?? "Unknown error")"

        pico = nil
        startScanning()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        pico = nil
        heartRate = nil
        spo2 = nil
        temperature = nil

        status = "Disconnected; scanning again..."
        startScanning()
    }
}

// MARK: - Receiving Sensor Data

extension BluetoothManager: CBPeripheralDelegate {

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        guard error == nil,
              let services = peripheral.services else {
            status = "Service discovery failed"
            return
        }

        guard let service = services.first(
            where: { $0.uuid == serviceUUID }
        ) else {
            status = "Pet Health Service not found"
            return
        }

        peripheral.discoverCharacteristics(
            [heartRateUUID, spo2UUID, temperatureUUID],
            for: service
        )
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil,
              let characteristics = service.characteristics else {
            status = "Characteristic discovery failed"
            return
        }

        let expected = [
            heartRateUUID,
            spo2UUID,
            temperatureUUID
        ]

        guard expected.allSatisfy({ wanted in
            characteristics.contains(where: { $0.uuid == wanted })
        }) else {
            status = "One or more measurement characteristics missing"
            return
        }

        for characteristic in characteristics
        where expected.contains(characteristic.uuid) {

            // Read current measurement
            peripheral.readValue(for: characteristic)

            // Subscribe to live updates
            peripheral.setNotifyValue(
                true,
                for: characteristic
            )
        }

        status = "Connected; waiting for measurements..."
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error = error {
            status = "Notification error: \(error.localizedDescription)"
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil,
              let data = characteristic.value,
              let raw = String(data: data, encoding: .utf8) else {
            status = "Unable to read Bluetooth value"
            return
        }

        let text = raw.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let measurement = Double(text)

        if characteristic.uuid == heartRateUUID {
            heartRate = measurement
        } else if characteristic.uuid == spo2UUID {
            spo2 = measurement
        } else if characteristic.uuid == temperatureUUID {
            temperature = measurement
        }

        status = "Receiving live sensor data"

        print("BLE \(characteristic.uuid): \(text)")
    }
}
