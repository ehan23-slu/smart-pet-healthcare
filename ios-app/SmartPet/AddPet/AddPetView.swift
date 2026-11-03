import SwiftUI

struct AddPetView: View {
    @EnvironmentObject var modelData: ModelData
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTab: ContentView.Tab

    @State private var name: String = ""
    @State private var species: Species = .dog
    @State private var weight: String = ""
    @State private var weightUnit: WeightUnit = .lb
    @State private var birthDate: Date = Date()
    @State private var petPhotoData: Data?
    @State private var isShowingPhotoPicker = false
    @State private var showAlert = false

    private let maxChars = 20

    var body: some View {
        NavigationSplitView(
            sidebar: {
                VStack(spacing: 0) {
                    // Photo Section
                    VStack {
                        Button(action: {
                            isShowingPhotoPicker = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .frame(width: 100, height: 100)
                                    .background(Color.white)
                                    .cornerRadius(50)
                                    .shadow(radius: 5)

                                if let imageData = petPhotoData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 50))
                                        .clipped()
                                } else {
                                    VStack(spacing: 4) {
                                                Image(systemName: "pawprint.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .foregroundColor(.gray)
                                                    .frame(width: 40, height: 40)

                                                Image(systemName: "plus.circle.fill")
                                                    .resizable()
                                                    .foregroundColor(.blue)
                                                    .frame(width: 20, height: 20)
                                            }
                                        }
                            }
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $isShowingPhotoPicker) {
                            PetImagePicker(selectedImageData: $petPhotoData)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)
                    .padding(.bottom, 10)
                    .background(Color(UIColor.systemGray6))

                    // Form Section
                    Form {
                        Section {
                            TextField("Name", text: $name)
                            // onChange != for loop
                            // it runs a block of code once,
                            // in each time the observed value changes
                                .onChange(of: name) { newValue in
                                    let filtered = newValue.filter { $0.isLetter || $0.isWhitespace }
                                    if filtered.count > maxChars {
                                        name = String(filtered.prefix(maxChars))
                                    } else {
                                        name = filtered
                                    }
                                }

                            if name.count >= maxChars {
                                Text("Name cannot exceed \(maxChars) characters")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            Picker("Species", selection: $species) {
                                ForEach(Species.allCases) { type in
                                    Text("\(type.rawValue) \(type.description)").tag(type)
                                }
                            }

                            HStack {
                                TextField("Weight", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .onChange(of: weight) { newValue in
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

                                        weight = filtered
                                    }

                                Picker("Unit", selection: $weightUnit) {
                                    ForEach(WeightUnit.allCases) { unit in
                                        Text(unit.rawValue).tag(unit)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 100)
                            }

                            if Double(weight) == nil && !weight.isEmpty {
                                Text("Please enter a valid number for weight")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            DatePicker("Birthdate", selection: $birthDate, displayedComponents: [.date])
                        }

                        // continue Button
                        Section {
                            Button {
                                addPet()
                                showAlert = true
                            } label: {
                                Text("Continue")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(6)
                            }
                            .disabled(name.isEmpty || Double(weight) == nil)
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .alert("Pet added!", isPresented: $showAlert) {
                        Button("OK", role: .cancel) { }
                    }
                }
                .navigationTitle("My Pets")
            },
            detail: {
                Text("Add a new pet")
            }
        )
    }

    // Add Pet Logic
    private func addPet() {
        guard let weightValue = Double(weight) else { return }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: birthDate)
        let dateOnly = calendar.date(from: components)!

        let newPet = Pet(
            id: UUID(),
            name: name,
            species: species,
            weight: weightValue,
            weightUnit: weightUnit,
            birthDate: dateOnly,
            photo: petPhotoData
        )

        modelData.add(pet: newPet)
        dismiss()
        selectedTab = .featured
    }
}

struct AddPetView_Previews: PreviewProvider {
    static var previews: some View {
        AddPetView(selectedTab: .constant(.featured))
            .environmentObject(ModelData())
    }
}
