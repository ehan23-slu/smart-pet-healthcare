
import SwiftUI
import UIKit

struct HealthDataView: View {

    @Binding var pet: Pet

    // MARK: - Live Bluetooth Data
    @EnvironmentObject var bluetooth: BluetoothManager

    // Existing ViewModels for detail screens and charts
    @StateObject private var heartRateViewModel =
        HeartRateHistoryViewModel()

    @StateObject private var temperatureViewModel =
        TemperatureHistoryViewModel()

    @StateObject private var spO2ViewModel =
        SpO2HistoryViewModel()

    @State private var showingProfile = false

    // Scroll position
    @State private var scrollOffset: CGFloat = 0

    private let expandedHeaderHeight: CGFloat = 230
    private let collapsedHeaderHeight: CGFloat = 82
    private let collapseDistance: CGFloat = 140

    private let showScrollDebug = false

    // MARK: - Header Calculations

    private var collapseProgress: CGFloat {
        min(
            max(scrollOffset / collapseDistance, 0),
            1
        )
    }

    private var headerHeight: CGFloat {
        expandedHeaderHeight -
        (expandedHeaderHeight - collapsedHeaderHeight)
        * collapseProgress
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                // MARK: Collapsing Pet Header

                collapsingHeader
                    .frame(height: headerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .overlay(
                        Divider(),
                        alignment: .bottom
                    )
                    .shadow(
                        color: .black.opacity(
                            0.06 * collapseProgress
                        ),
                        radius: 6 * collapseProgress,
                        x: 0,
                        y: 3 * collapseProgress
                    )
                    .clipped()

                // MARK: Health Data Scroll Area

                ScrollView {

                    VStack(spacing: 20) {

                        // ====================================
                        // HEART RATE - LIVE BLUETOOTH DATA
                        // ====================================

                        NavigationLink {

                            HeartRateView(
                                pet: $pet,
                                viewModel: heartRateViewModel
                            )

                        } label: {

                            HealthMetricCard(
                                title: "Heart Rate",

                                value: bluetooth.heartRate.map {
                                    String(format: "%.1f", $0)
                                } ?? "--",

                                unit: "BPM",
                                icon: "heart.fill",
                                iconColor: .red,
                                rangeText: "Heart rate"
                            )
                        }

                        // ====================================
                        // TEMPERATURE - LIVE BLUETOOTH DATA
                        // ====================================

                        NavigationLink {

                            TemperatureView(
                                pet: $pet,
                                viewModel: temperatureViewModel
                            )

                        } label: {

                            HealthMetricCard(
                                title: "Temperature",

                                value: bluetooth.temperature.map {
                                    String(format: "%.2f", $0)
                                } ?? "--",

                                unit: "°C",
                                icon: "thermometer.medium",
                                iconColor: .orange,
                                rangeText: "Body temperature"
                            )
                        }

                        // ====================================
                        // SpO2 - LIVE BLUETOOTH DATA
                        // ====================================

                        NavigationLink {

                            SpO2View(
                                pet: $pet,
                                viewModel: spO2ViewModel
                            )

                        } label: {

                            HealthMetricCard(
                                title: "SpO₂",

                                value: bluetooth.spo2.map {
                                    String(format: "%.1f", $0)
                                } ?? "--",

                                unit: "%",
                                icon: "drop.fill",
                                iconColor: .cyan,
                                rangeText: "Oxygen saturation"
                            )
                        }
                        
                        
                        Button {

                            // Get current measurements from Bluetooth
                            guard let heartRate = bluetooth.heartRate,
                                  let spo2 = bluetooth.spo2,
                                  let temperature = bluetooth.temperature else {

                                print("Cannot save: Measurements are incomplete")
                                return
                            }

                            // Save to Firebase
                            FirebaseService.saveMeasurement(
                                heartRate: heartRate,
                                spo2: spo2,
                                temperature: temperature
                            )

                            print("Firebase save requested")

                        } label: {

                            Label(
                                "Save Test Measurement",
                                systemImage: "icloud.and.arrow.up"
                            )
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            bluetooth.heartRate == nil ||
                            bluetooth.spo2 == nil ||
                            bluetooth.temperature == nil
                        )


                        // ====================================
                        // OTHER METRICS
                        // Not connected to sensors yet
                        // ====================================

                        HealthMetricCard(
                            title: "Respiratory Rate",
                            value: "--",
                            unit: "RPM",
                            icon: "lungs.fill",
                            iconColor: .blue,
                            rangeText: "Respiratory rate"
                        )

                        HealthMetricCard(
                            title: "Activity",
                            value: "--",
                            unit: "steps",
                            icon: "figure.walk",
                            iconColor: .green,
                            rangeText: "Daily activity"
                        )

                        HealthMetricCard(
                            title: "Sleep",
                            value: "--",
                            unit: "hrs",
                            icon: "moon.fill",
                            iconColor: .indigo,
                            rangeText: "Sleep duration"
                        )

                        // MARK: Bluetooth Status

                        Text(
                            bluetooth.heartRate != nil ||
                            bluetooth.spo2 != nil ||
                            bluetooth.temperature != nil
                            ? "Live sensor data"
                            : "Waiting for sensor data..."
                        )
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 20)
                    }
                    .padding(.horizontal)
                    .padding(.top, 18)
                    .background {

                        ScrollViewOffsetObserver(
                            offset: $scrollOffset
                        )
                        .frame(width: 1, height: 1)
                    }
                }
            }

            // MARK: Toolbar

            .toolbar {

                ToolbarItem(
                    placement: .navigationBarTrailing
                ) {

                    Button {
                        showingProfile.toggle()
                    } label: {

                        Image(
                            systemName: "person.crop.circle"
                        )
                        .imageScale(.large)
                    }
                }
            }

            // MARK: Profile Sheet

            .sheet(isPresented: $showingProfile) {

                ProfileHost(
                    pet: $pet
                )
            }

            // MARK: Initialize ViewModels

            .onAppear {

                heartRateViewModel.selectedPet = pet

                temperatureViewModel.selectedPet = pet

                spO2ViewModel.selectedPet = pet
            }
        }
    }

    // MARK: - Collapsing Header

    private var collapsingHeader: some View {

        ZStack {

            // Expanded Header

            GridPetImage(pet: pet)

                .scaleEffect(
                    1 - (0.15 * collapseProgress)
                )

                .offset(y: -8 * collapseProgress)

                .opacity(
                    max(
                        1 - (collapseProgress * 1.6),
                        0
                    )
                )

                .allowsHitTesting(false)

            // Compact Header

            compactPetHeader

                .opacity(
                    min(
                        max(
                            (collapseProgress - 0.15) / 0.85,
                            0
                        ),
                        1
                    )
                )

                .offset(
                    y: 8 * (1 - collapseProgress)
                )

                .allowsHitTesting(false)

            // Debug Display

            if showScrollDebug {

                VStack {

                    HStack {

                        Text(
                            "offset: \(Int(scrollOffset))   progress: \(collapseProgress, specifier: "%.2f")"
                        )
                        .font(.caption2)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Color.white.opacity(0.85)
                        )
                        .clipShape(Capsule())

                        Spacer()
                    }

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .zIndex(100)
            }
        }
    }

    // MARK: - Compact Pet Header

    private var compactPetHeader: some View {

        HStack(spacing: 12) {

            if let data = pet.photo,
               let uiImage = UIImage(data: data) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())

            } else {

                Image(systemName: "pawprint.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.gray)
            }

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(pet.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("Health Summary")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

// ======================================================
// MARK: - UIScrollView Offset Observer
// ======================================================

private struct ScrollViewOffsetObserver:
    UIViewRepresentable {

    @Binding var offset: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(offset: $offset)
    }

    func makeUIView(
        context: Context
    ) -> UIView {

        let view = UIView(frame: .zero)

        view.isUserInteractionEnabled = false

        DispatchQueue.main.async {
            context.coordinator.attach(to: view)
        }

        return view
    }

    func updateUIView(
        _ uiView: UIView,
        context: Context
    ) {

        DispatchQueue.main.async {
            context.coordinator.attach(to: uiView)
        }
    }

    final class Coordinator: NSObject {

        private var offset: Binding<CGFloat>

        private weak var scrollView: UIScrollView?

        private var observation: NSKeyValueObservation?

        init(offset: Binding<CGFloat>) {
            self.offset = offset
        }

        func attach(to view: UIView) {

            guard let foundScrollView =
                findScrollView(from: view)
            else {

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.05
                ) { [weak self, weak view] in

                    guard let self,
                          let view else {
                        return
                    }

                    self.attach(to: view)
                }

                return
            }

            if scrollView === foundScrollView {
                return
            }

            observation?.invalidate()

            scrollView = foundScrollView

            observation = foundScrollView.observe(
                \.contentOffset,
                options: [.initial, .new]
            ) { [weak self] scrollView, _ in

                let y = max(
                    scrollView.contentOffset.y +
                    scrollView.adjustedContentInset.top,
                    0
                )

                DispatchQueue.main.async {
                    self?.offset.wrappedValue = y
                }
            }
        }

        private func findScrollView(
            from view: UIView
        ) -> UIScrollView? {

            var current: UIView? = view

            while let currentView = current {

                if let scroll =
                    currentView as? UIScrollView {

                    return scroll
                }

                current = currentView.superview
            }

            return nil
        }

        deinit {
            observation?.invalidate()
        }
    }
}

// ======================================================
// MARK: - Health Metric Card
// ======================================================

private struct HealthMetricCard: View {

    let title: String
    let value: String
    let unit: String
    let icon: String
    let iconColor: Color
    let rangeText: String

    var body: some View {

        HStack(spacing: 18) {

            ZStack {

                Circle()
                    .fill(
                        iconColor.opacity(0.12)
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 25))
                    .foregroundColor(iconColor)
            }

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(
                    alignment: .firstTextBaseline,
                    spacing: 4
                ) {

                    Text(value)
                        .font(
                            .system(
                                size: 30,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(.primary)

                    Text(unit)
                        .font(.headline)
                        .foregroundColor(.gray)
                }

                Text(rangeText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text("View")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Color.gray.opacity(0.1)
                )
                .clipShape(Capsule())
        }
        .padding()
        .background {

            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .padding(.horizontal, 5)
    }
}

// ======================================================
// MARK: - Preview
// ======================================================

private struct HealthDataPreviewWrapper: View {

    @State private var pet = Pet(
        id: UUID(),
        name: "Max",
        species: .dog,
        weight: 4.5,
        weightUnit: .kg,
        birthDate: Date()
    )

    var body: some View {

        HealthDataView(
            pet: $pet
        )
        .environmentObject(BluetoothManager())
    }
}

#Preview {
    HealthDataPreviewWrapper()
}

