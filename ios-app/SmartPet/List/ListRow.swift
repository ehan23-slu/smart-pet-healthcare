import SwiftUI
import UIKit

struct ListRow: View {
    var pet: Pet

    var body: some View {
        HStack(spacing: 16) {
            if let data = pet.photo, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "pawprint.circle")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.gray)
            }

            Text(pet.name)
                .font(.title3)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
//#Preview {
//    ListRow(pet: .init(id: UUID(), name: "Fluffykins", species: Species.dog,weight: 10, weightUnit: .kg, birthDate: Date(), photo: nil))
//}
