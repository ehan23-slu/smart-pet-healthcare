import SwiftUI

struct ProfileHost: View {
    @Binding var pet: Pet
    @Environment(\.editMode) private var editMode

    @State private var draftPet: Pet = Pet(
        id: UUID(),
        name: "",
        species: .dog,
        weight: 0.0,
        weightUnit: .kg,
        birthDate: Date(),
        photo: nil
    )


    var isEditing: Bool {
        editMode?.wrappedValue == .active
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                if isEditing {
                    Button("Cancel", role: .cancel) {
                        draftPet = pet
                        editMode?.animation().wrappedValue = .inactive
                    }
                }
                Spacer()
                EditButton()
            }

            ZStack {
                // Always load both views, but hide depending on edit mode
                Profile(pet: pet)
                    .opacity(isEditing ? 0 : 1)

                ProfileEditor(pet: $draftPet)
                    .opacity(isEditing ? 1 : 0)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            draftPet = pet
        }
        .onChange(of: editMode?.wrappedValue) { newValue in
            if newValue == .active {
                draftPet = pet
            } else if newValue == .inactive {
                pet = draftPet
            }
        }
    }
}

#Preview {
    struct PreviewContainer: View {
        @State private var previewPet = Pet(
            id: UUID(),
            name: "Buddy",
            species: .cat,
            weight: 3.4,
            weightUnit: .kg,
            birthDate: Date(),
            photo: nil
        )

        var body: some View {
            ProfileHost(pet: $previewPet)
        }
    }

    return PreviewContainer()
}
