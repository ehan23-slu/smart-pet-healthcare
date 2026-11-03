import SwiftUI
import UIKit

struct GridPetImage: View {
    @EnvironmentObject var modelData: ModelData
    var pet: Pet

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading) {
                if let data = pet.photo, let uiImage = UIImage(data: data) {
                    HStack {
                        Spacer()
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(Circle())
                            .frame(width: 110, height: 110)
                        Spacer()
                    }
                } else {
                    // Default placeholder if no photo
                    HStack {
                        Spacer()
                        Image(systemName: "pawprint.circle")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 110, height: 110)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                }

                HStack {
                    Spacer()
                    Text(pet.name)
                        .foregroundStyle(.primary)
                        .font(.title)
                    Spacer()
                }
            }
            
        }
    }
}

//#Preview {
//    GridPetImage(pet: Pet(
//        id: UUID(),
//        name: "Bella",
//        species: .cat,
//        weight: 4.5,
//        weightUnit: .kg,
//        birthDate: Date()
//    ))
//    .environmentObject(ModelData())
//}
