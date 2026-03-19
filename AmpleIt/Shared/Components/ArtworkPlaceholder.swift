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
        ArtworkPlaceholder.seedUInt64(for: seed)
    }

    // MARK: - UIKit render (for lock screen / Now Playing info)

    /// Renders the same gradient + music note as the SwiftUI view into a UIImage.
    /// Uses pure UIKit so it is safe to call from any thread.
    static func makeUIImage(seed: String, size: CGSize = CGSize(width: 600, height: 600)) -> UIImage {
        let seedVal = seedUInt64(for: seed)
        var generator = SeededGenerator(seed: seedVal)
        let hueA         = Double.random(in: 0...1,        using: &generator)
        let hueB         = Double.random(in: 0...1,        using: &generator)
        let accentOpacity = Double.random(in: 0.18...0.34, using: &generator)

        let colorA = UIColor(hue: hueA, saturation: 0.25, brightness: 0.92, alpha: 0.85)
        let colorB = UIColor(hue: hueB, saturation: 0.55, brightness: 0.85, alpha: CGFloat(accentOpacity))

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let space = CGColorSpaceCreateDeviceRGB()
            let colors = [colorA.cgColor, colorB.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) {
                cgCtx.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }
            let ptSize = size.width * 0.35
            let config = UIImage.SymbolConfiguration(pointSize: ptSize, weight: .semibold)
            if let symbol = UIImage(systemName: "music.note", withConfiguration: config) {
                let tinted = symbol.withTintColor(
                    UIColor.label.withAlphaComponent(0.30),
                    renderingMode: .alwaysOriginal
                )
                let origin = CGPoint(
                    x: (size.width  - tinted.size.width)  / 2,
                    y: (size.height - tinted.size.height) / 2
                )
                tinted.draw(at: origin)
            }
        }
    }

    private static func seedUInt64(for string: String) -> UInt64 {
        UInt64(string.unicodeScalars.reduce(into: UInt64(0)) { partial, scalar in
            partial = (partial &* 31) &+ UInt64(scalar.value)
        })
    }
}

#Preview("Artwork Placeholder") {
    HStack(spacing: 12) {
        ArtworkPlaceholder(seed: "preview-a")
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        ArtworkPlaceholder(seed: "preview-b")
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        ArtworkPlaceholder(seed: "preview-c")
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    .padding()
}
