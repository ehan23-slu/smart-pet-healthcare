import Foundation
import FirebaseAuth
import FirebaseFirestore

struct FirebaseService {

    static func saveMeasurement(
        heartRate: Double,
        spo2: Double,
        temperature: Double
    ) {

        // 1. Get the current Firebase user
        guard let user = Auth.auth().currentUser else {
            print("Firebase: User not signed in")
            return
        }

        // 2. Check numeric values
        guard heartRate.isFinite,
              spo2.isFinite,
              temperature.isFinite else {
            print("Firebase: Invalid measurement values")
            return
        }

        // 3. Prepare sensor data
        let data: [String: Any] = [
            "heartRate": heartRate,
            "spo2": spo2,
            "temperature": temperature,
            "deviceId": "PetHealthMonitor",
            "timestamp": FieldValue.serverTimestamp()
        ]

        // 4. Save data to Firestore
        Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .collection("measurements")
            .addDocument(data: data) { error in

                if let error = error {
                    print(
                        "Firebase save failed:",
                        error.localizedDescription
                    )
                } else {
                    print("Measurement saved to Firebase!")
                }
            }
    }
}

// Add a temporary Save Measurement button to save the three
// actual Bluetooth measurements to Firebase
// not starting autosave from the start is that saving every time
// a measurement is received can generate more documents than expected
