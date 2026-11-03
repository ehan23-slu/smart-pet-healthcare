import SwiftUI

struct Profile: View {
    var pet: Pet  // Accept the pet directly
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(pet.name)
                    .bold()
                    .font(.title)
                Spacer()
                
                Text("\(pet.name)'s Species: \(pet.species.description)")
                Text("\(pet.name)'s Weight: \(String(format: "%.2f", pet.weight)) \(pet.weightUnit.rawValue)")
                Text("\(pet.name)'s Birthday: \(pet.birthDate.formatted(date: .abbreviated, time: .omitted))")
            }
            .padding()
        }
    }
}

//#Preview {
//    Profile(pet: Pet(
//        id: UUID(),
//        name: "Milo",
//        species: .cat,
//        weight: 4.5,
//        weightUnit: .kg,
//        birthDate: Date(),
//        photo: nil
//    ))
//}
