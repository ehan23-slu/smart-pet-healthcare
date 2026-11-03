//  Temperature.swift
import SwiftUI

struct TemperatureView: View {

    @Binding var pet: Pet
    @ObservedObject var viewModel: TemperatureHistoryViewModel
    @EnvironmentObject private var bluetooth: BluetoothManager
    @State private var showingProfile = false
    
    private var dummyGraphData: [VitalTrendPoint] {
            loadHeartRateJSON()
        }


    var body: some View {

        NavigationStack {

            VStack {

                Text("\(pet.name)'s Temperature")
                    .font(.title)

                Spacer().frame(height: 90)

                VitalCircle(
                    value: bluetooth.temperature.map {
                        String(format: "%.2f", $0)
                    } ?? "--",
                    unit: "°C",
                    shadowColor: .orange
                )

                Spacer().frame(height: 70)

                VitalTrendChart(
                    title: "Temperature Trend",
                    data: dummyGraphData,
                    color: .orange
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

private struct TempPreviewWrapper: View {

    @State private var pet = Pet(
        id: UUID(),
        name: "Max",
        species: .dog,
        weight: 4.5,
        weightUnit: .kg,
        birthDate: Date()
    )

    @StateObject private var viewModel = TemperatureHistoryViewModel()

    var body: some View {
        TemperatureView(
            pet: $pet,
            viewModel: viewModel
        )
    }
}

#Preview {
    TempPreviewWrapper()
        .environmentObject(BluetoothManager())
}
