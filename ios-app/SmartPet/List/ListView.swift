import SwiftUI

struct ListView: View {
    @EnvironmentObject var modelData: ModelData
    @State private var selectedPetId: UUID?

    @StateObject private var heartRateViewModel = HeartRateHistoryViewModel()


    var body: some View {
        NavigationSplitView {
            // Sidebar list
            if modelData.pets.isEmpty {
                VStack {
                    Spacer()
                    Text("No pets yet")
                        .foregroundColor(.gray)
                    Spacer()
                }
                .navigationTitle("My Pets")
            } else {
                List(selection: $selectedPetId) {
                    ForEach(modelData.pets) { pet in
                        NavigationLink(
                            value: pet.id
                        ) {
                            ListRow(pet: pet)
                        }
                        .tag(pet.id) // tag by id to link selection
                    }
                }
                .navigationTitle("My Pets")
            }
        } detail: {
            if let selectedId = selectedPetId,
               let index = modelData.pets.firstIndex(where: { $0.id == selectedId }) {
                HeartRateView(pet: $modelData.pets[index], viewModel: heartRateViewModel)
            } else {
                Text("Select a pet")
            }
        }
        .navigationSplitViewStyle(.balanced)
        .navigationDestination(for: UUID.self) { petId in
            if let index = modelData.pets.firstIndex(where: { $0.id == petId }) {
                HeartRateView(pet: $modelData.pets[index], viewModel: heartRateViewModel)
            } else {
                Text("Pet not found")
            }
        }
    }
}
