import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ModelData
    @Binding var selectedTab: ContentView.Tab
    @State private var isShowingAddPet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.pets.isEmpty {
                            VStack {
                                Spacer(minLength: 200)

                                Text("No pets added yet.")

                                Text("Click the button to add your pet!")
                                    .foregroundStyle(.gray)
                                    .font(.title3)

                                Spacer()
                            }
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )

                        } else {
                            GridCol()
                                .environmentObject(viewModel)
                        }
                    }
                    .padding()
                }
            }

            .navigationTitle("My Pets")

            .overlay(
                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        Button {
                            isShowingAddPet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            )

            .sheet(isPresented: $isShowingAddPet) {
                AddPetView(selectedTab: $selectedTab)
                    .environmentObject(viewModel)
            }
        }
    }
}

#Preview {
    let viewModel = ModelData()
    
    return HomeView(selectedTab: .constant(.featured))
        .environmentObject(viewModel)
}
