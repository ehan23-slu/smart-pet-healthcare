import SwiftUI

struct BluetoothTestView: View {

    @StateObject private var bluetooth = BluetoothManager()

    var body: some View {
        VStack(spacing: 22) {

            Text("Pet Health Monitor")
                .font(.title)
                .bold()

            Text(bluetooth.status)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            metric(
                "Heart Rate",
                value: bluetooth.heartRate,
                unit: "BPM",
                decimals: 1
            )

            metric(
                "SpO₂",
                value: bluetooth.spo2,
                unit: "%",
                decimals: 1
            )

            metric(
                "Temperature",
                value: bluetooth.temperature,
                unit: "°C",
                decimals: 2
            )
        }
        .padding()
    }

    private func metric(
        _ title: String,
        value: Double?,
        unit: String,
        decimals: Int
    ) -> some View {

        HStack {
            Text(title)

            Spacer()

            if let value = value {
                Text(
                    "\(value.formatted(.number.precision(.fractionLength(decimals)))) \(unit)"
                )
                .monospacedDigit()
                .bold()

            } else {
                Text("Measuring...")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
