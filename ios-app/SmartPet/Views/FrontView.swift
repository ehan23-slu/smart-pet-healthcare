import SwiftUI

struct FrontView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 210)
        }
    }
}

#Preview {
    FrontView()
}
