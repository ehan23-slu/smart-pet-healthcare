import SwiftUI

struct SpO2View: View {

    @Binding var pet: Pet
    @ObservedObject var viewModel: SpO2HistoryViewModel
    @EnvironmentObject private var bluetooth: BluetoothManager
    @State private var showingProfile = false
    
    private var dummyGraphData: [VitalTrendPoint] {
        loadHeartRateJSON()
    }

    var body: some View {

        NavigationStack {

            VStack {

                Text("\(pet.name)'s SpO₂")
                    .font(.title)

                Spacer().frame(height: 90)

                VitalCircle(
                    value: bluetooth.spo2.map {
                        String(format: "%.1f", $0)
                    } ?? "--",
                    unit: "%",
                    shadowColor: .cyan
                )

                Spacer().frame(height: 70)

                VitalTrendChart(
                    title: "SpO₂ Trend",
                    data: dummyGraphData,
                    color: .cyan
                )
            }

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingProfile.toggle()
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .imageScale(.large)
                    }
                }
            }

            .sheet(isPresented: $showingProfile) {
                ProfileHost(pet: $pet)
            }

            .onAppear {
                viewModel.selectedPet = pet
            }
        }
    }
}

private struct SpO2PreviewWrapper: View {

    @State private var pet = Pet(
        id: UUID(),
        name: "Max",
        species: .dog,
        weight: 4.5,
        weightUnit: .kg,
        birthDate: Date()
    )

    @StateObject private var viewModel = SpO2HistoryViewModel()

    var body: some View {
        SpO2View(
            pet: $pet,
            viewModel: viewModel
        )
    }
}

#Preview {
    SpO2PreviewWrapper()
        .environmentObject(BluetoothManager())
}
