import SwiftUI
import UIKit

struct GridPet: View {
    @EnvironmentObject var modelData: ModelData
    @State private var showDeleteConfirmation = false
    var pet: Pet

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GridPetImage(pet: pet)
                .frame(width: 130, height: 230)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray, lineWidth: 0.2)
                        .shadow(radius: 3)
                )

            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
            }
            .padding(6)
            .offset(x: -5, y: 5)
        }
        .alert("Remove this pet?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelData.delete(pet: pet)
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

//#Preview {
//    GridPet(pet: Pet(
//        id: UUID(),
//        name: "Bella",
//        species: .cat,
//        weight: 4.5,
//        weightUnit: .kg,
//        birthDate: Date()
//    ))
//    .environmentObject(ModelData())
//}
