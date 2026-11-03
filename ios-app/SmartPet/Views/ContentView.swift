import SwiftUI

struct ContentView: View {
    @State private var selection: Tab = .featured
    @StateObject private var modelData = ModelData()
    
    enum Tab {
        case featured
        case list
    }
    
    var body: some View {
        TabView(selection: $selection) {
            HomeView(selectedTab: $selection)
                .tabItem {
                    Label("My Pets", systemImage: "house")
                }
                .tag(Tab.featured)
            
            ListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
                .tag(Tab.list)
        }
        .environmentObject(modelData)
    }
}

#Preview {
    ContentView()
}
