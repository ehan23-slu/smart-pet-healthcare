import SwiftUI

@main
struct SmartPetApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    @StateObject var modelData = ModelData()

    @StateObject private var bluetooth = BluetoothManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(bluetooth)
        }
    }
}
