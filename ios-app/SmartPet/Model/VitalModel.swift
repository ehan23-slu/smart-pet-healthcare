// Heart Rate data model + heart-rate simulator

import Foundation
import Combine

// One feed (i.e., one record in the 'feeds' array)
struct Feed: Identifiable, Codable {
    var id: Int { entry_id }
    let entry_id: Int
    let created_at: Date
    let field1: String?
}

struct HeartRateResponse: Codable {
    let feeds: [Feed]
}

struct HeartRateEntry: Identifiable {
    var id = UUID()
    var bpm: Int
    var timestamp: Date
}

extension Feed {
    func toHeartRateEntry() -> HeartRateEntry? {
        guard let bpmString = field1,
              let bpmDouble = Double(bpmString) else { return nil }
        return HeartRateEntry(bpm: Int(bpmDouble), timestamp: created_at)
    }
}


// 1. load all heart rate entries into an array
// 2. use a timer to update every few sec
// 3. show each heartrate in order
class HeartRateHistoryViewModel: ObservableObject {
    @Published var latestHeartRate: Int = 0
    @Published var selectedPet: Pet?
    private var heartRates: [HeartRateEntry] = []
    private var timer: Timer?
    private var currentIndex = 0
    
     // THIS IS FOR DEVELOPMENT ONLY
    func overwriteJSONFromBundle() {
        let fileManager = FileManager.default
        let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = docDir.appendingPathComponent("VitalData.json")

        if let bundleURL = Bundle.main.url(forResource: "VitalData", withExtension: "json") {
            do {
                // Remove old version in Documents
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }

                // Copy updated one from bundle
                try fileManager.copyItem(at: bundleURL, to: destinationURL)
                print("✅ Overwrote VitalData.json with fresh bundle copy")
            } catch {
                print("❌ Failed to overwrite VitalData.json: \(error)")
            }
        }
    }
    // THIS IS FOR DEVELOPMENT ONLY


    init() {
// Temporarily disable old JSON simulation
//        overwriteJSONFromBundle()
//        loadData()
    }

    func loadData() {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docDir.appendingPathComponent("VitalData.json")

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let response = try decoder.decode(HeartRateResponse.self, from: data)

            // Parse and sort entries by date
            self.heartRates = response.feeds
                .compactMap { $0.toHeartRateEntry() }
                .sorted(by: { $0.timestamp < $1.timestamp })

            print("Feed count: \(response.feeds.count)")
            if let last = response.feeds.last {
                print("Last feed: entry_id=\(last.entry_id), field1=\(String(describing: last.field1))")
            }

            startTimer()

        } catch {
            print("Error loading JSON:", error)
        }
    }

    // Show one entry every 3 min
    // just like Apple Watch (measure 3 min - 7 min)
    private func startTimer() {
        timer?.invalidate()
        currentIndex = 0
        // Show one entry every 3 minutes (180 seconds)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if currentIndex < heartRates.count {
                let next = heartRates[currentIndex]
                self.latestHeartRate = next.bpm
                print("Showing BPM: \(next.bpm) at \(next.timestamp)")
                
                if let pet = self.selectedPet {
                    BPMMonitor.shared.checkBPM(for: pet, bpm: next.bpm)
                }
                currentIndex += 1
            } else {
                timer?.invalidate()
                print("Done cycling through all heart rate entries.")
            }
        }
    }
}

final class SpO2HistoryViewModel: ObservableObject {
    @Published var latestSpO2: Int = 97
    var selectedPet: Pet?
}

final class TemperatureHistoryViewModel: ObservableObject {
    @Published var latestTemp: Double = 38.2
    var selectedPet: Pet?
}
