import SwiftUI

struct ArtworkPlaceholder: View {
    let seed: String
    var symbolSize: CGFloat = 34

    var body: some View {
        let palette = seededPalette

        ZStack {
            LinearGradient(
                colors: palette,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "music.note")
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.30))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var seededPalette: [Color] {
        var generator = SeededGenerator(seed: seedValue)
        let hueA = Double.random(in: 0...1, using: &generator)
        let hueB = Double.random(in: 0...1, using: &generator)
        let accentOpacity = Double.random(in: 0.18...0.34, using: &generator)
        return [
            Color(hue: hueA, saturation: 0.25, brightness: 0.92).opacity(0.85),
            Color(hue: hueB, saturation: 0.55, brightness: 0.85).opacity(accentOpacity)
        ]
    }

    private var seedValue: UInt64 {
        UInt64(seed.unicodeScalars.reduce(into: 0) { partial, scalar in
            partial = (partial &* 31) &+ UInt64(scalar.value)
        })
    }
}
