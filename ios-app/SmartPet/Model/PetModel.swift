import SwiftUI

// MARK: - Species Enum
enum Species: String, CaseIterable, Identifiable, Codable, Hashable {
    case dog = "🐶"
    case cat = "🐱"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .dog: return "Dog"
        case .cat: return "Cat"
        }
    }
}

enum WeightUnit: String, CaseIterable, Identifiable, Codable, Hashable {
    case lb
    case kg

    var id: String { rawValue }
}

struct Pet: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var species: Species
    var weight: Double
    var weightUnit: WeightUnit
    var birthDate: Date
    var photo: Data?
}
