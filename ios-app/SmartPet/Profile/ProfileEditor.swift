import SwiftUI

struct ProfileEditor: View {
    @Binding var pet: Pet

    @State private var editableName: String = ""
    @State private var editableWeight: String = ""
    private let maxChars = 20

    var body: some View {
        List {
            // Name Field
            HStack {
                Text("Pet's Name")
                Spacer()
                TextField("Pet's Name", text: $editableName)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: editableName) { newValue in
                        let filtered = newValue.filter { $0.isLetter || $0.isWhitespace }
                        if filtered.count > maxChars {
                            editableName = String(filtered.prefix(maxChars))
                        } else {
                            editableName = filtered
                        }
                        pet.name = editableName
                    }
            }

            if editableName.count >= maxChars {
                Text("Name cannot exceed \(maxChars) characters")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Species Picker
            Picker("Pet's Species", selection: $pet.species) {
                ForEach(Species.allCases) { type in
                    Text("\(type.rawValue) \(type.description)").tag(type)
                }
            }

            // Weight Field + Unit Picker
            HStack {
                Text("Pet's Weight")
                Spacer()
                TextField("Pet's Weight", text: $editableWeight)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: editableWeight) { newValue in
                        var filtered = newValue.filter { "0123456789.".contains($0) }

                        let decimalCount = filtered.filter { $0 == "." }.count
                        if decimalCount > 1 {
                            if let firstDecimalIndex = filtered.firstIndex(of: ".") {
                                let beforeDecimal = filtered.prefix(through: firstDecimalIndex)
                                let afterDecimal = filtered.suffix(from: filtered.index(after: firstDecimalIndex)).filter { $0 != "." }
                                filtered = String(beforeDecimal + afterDecimal)
                            }
                        }

                        if let decimalIndex = filtered.firstIndex(of: ".") {
                            let fractionalPart = filtered.suffix(from: filtered.index(after: decimalIndex))
                            if fractionalPart.count > 2 {
                                let allowedFraction = fractionalPart.prefix(2)
                                let integerPart = filtered.prefix(upTo: filtered.index(after: decimalIndex))
                                filtered = String(integerPart + allowedFraction)
                            }
                        }

                        editableWeight = filtered
                        pet.weight = Double(filtered) ?? pet.weight
                    }

                Picker("Unit", selection: $pet.weightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }

            if Double(editableWeight) == nil && !editableWeight.isEmpty {
                Text("Please enter a valid number for weight")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Birthdate Picker
            DatePicker("Pet's Birthday", selection: $pet.birthDate, displayedComponents: .date)
        }
        .onAppear {
            editableName = pet.name
            editableWeight = String(format: "%.2f", pet.weight)
        }
    }
}

#Preview {
    @State var previewPet = Pet(
        id: UUID(),
        name: "Milo",
        species: .cat,
        weight: 4.5,
        weightUnit: .kg,
        birthDate: Date(),
        photo: nil
    )

    return ProfileEditor(pet: $previewPet)
}
