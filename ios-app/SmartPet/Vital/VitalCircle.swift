import SwiftUI

struct VitalCircle: View {
    let value: String
    let unit: String
    let shadowColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .shadow(
                    color: shadowColor.opacity(1.5),
                    radius: 12
                )

            VStack {
                Text(value)
                    .font(.system(size: 40))
                    .foregroundColor(.gray)

                Text(unit)
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 220, height: 220)
    }
}

#Preview {
    VitalCircle(
        value: "125",
        unit: "BPM",
        shadowColor: .green
    )
}
