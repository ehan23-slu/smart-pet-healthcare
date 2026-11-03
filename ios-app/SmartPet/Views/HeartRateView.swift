import SwiftUI

struct HeartRateView: View {
    @Binding var pet: Pet
    @ObservedObject var viewModel: HeartRateHistoryViewModel
    @EnvironmentObject private var bluetooth: BluetoothManager
    @Environment(\.dismiss) var dismiss
    @State private var showingProfile = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("\(pet.name)'s Heart Rate")   // you can show name dynamically
                    .font(.title)
                
                Spacer().frame(height: 90)
                
                VitalCircle(
                    value: bluetooth.heartRate.map {
                        String(format: "%.1f", $0)
                    } ?? "--",
                    unit: "BPM",
                    shadowColor: .gray
                )
                
                Spacer().frame(height: 70)
                
                GridPetImage(pet: pet)
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
                ProfileHost(pet: $pet)      // pass binding here
            }
            .onAppear {
                viewModel.selectedPet = pet
            }
        }
    }
}


private struct PreviewWrapper: View {
    @StateObject private var viewModel: HeartRateHistoryViewModel
    @State private var pet: Pet

    init() {
        let fileManager = FileManager.default
        let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = docDir.appendingPathComponent("VitalData.json")

        // Copy file if needed
        if !fileManager.fileExists(atPath: destinationURL.path),
           let bundleURL = Bundle.main.url(forResource: "VitalData", withExtension: "json") {
            do {
                try fileManager.copyItem(at: bundleURL, to: destinationURL)
                print("Copied VitalData.json to documents")
            } catch {
                print("Failed to copy VitalData.json:", error)
            }
        }

        _viewModel = StateObject(wrappedValue: HeartRateHistoryViewModel())
        _pet = State(initialValue: Pet(
            id: UUID(),
            name: "Max",
            species: .dog,
            weight: 4.5,
            weightUnit: .kg,
            birthDate: Date()
        ))
    }

    var body: some View {
        HeartRateView(pet: $pet, viewModel: viewModel)
    }
}

#Preview {
    PreviewWrapper()
        .environmentObject(BluetoothManager())
}
