import Foundation

class ModelData: ObservableObject {
    @Published var pets: [Pet] = []
    
    private let petsKey = "SavedPets"
    
    init() {
        loadPets()
    }
    
    func add(pet: Pet) {
        pets.append(pet)
        savePets()
    }
    
    func delete(pet: Pet) {
        pets.removeAll { $0.id == pet.id }
        savePets()
    }
    
    func savePets() {
        if let encoded = try? JSONEncoder().encode(pets) {
            UserDefaults.standard.set(encoded, forKey: petsKey)
        }
    }
    
    func loadPets() {
        if let data = UserDefaults.standard.data(forKey: petsKey),
           let decoded = try? JSONDecoder().decode([Pet].self, from: data) {
            pets = decoded
        }
    }
}
