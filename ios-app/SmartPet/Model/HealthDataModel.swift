import Foundation

struct HealthDataResponse: Codable {
    let feeds: [HealthDataFeed]
}

struct HealthDataFeed: Codable {
    let createdAt: String
    let entryId: Int
    let field1: String?

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case entryId = "entry_id"
        case field1
    }
}

func loadHeartRateJSON() -> [VitalTrendPoint] {

    guard let url = Bundle.main.url(
        forResource: "VitalData",
        withExtension: "json"
    ) else {
        print("VitalData.json not found")
        return []
    }

    do {
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()

        let response = try decoder.decode(
            HealthDataResponse.self,
            from: data
        )

        let formatter = ISO8601DateFormatter()

        return response.feeds.compactMap { feed in

            guard
                let valueString = feed.field1,
                let value = Double(valueString),
                let date = formatter.date(from: feed.createdAt)
            else {
                return nil
            }

            return VitalTrendPoint(
                date: date,
                value: value
            )
        }

    } catch {
        print("JSON decoding error:", error)
        return []
    }
}
