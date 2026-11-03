import SwiftUI

struct GridCol: View {
    @EnvironmentObject var modelData: ModelData

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(
                    Array(modelData.pets.enumerated()),
                    id: \.element.id
                ) { index, pet in

                    NavigationLink {
                        HealthDataView(
                            pet: $modelData.pets[index]
                        )
                    } label: {
                        GridPet(pet: pet)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
