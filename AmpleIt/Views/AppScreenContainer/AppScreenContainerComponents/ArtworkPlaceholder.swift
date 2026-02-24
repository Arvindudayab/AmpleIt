import SwiftUI

struct ArtworkPlaceholder: View {
    let seed: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.03),
                    Color("AppAccent").opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "music.note")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.28))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}
