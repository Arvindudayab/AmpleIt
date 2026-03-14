import SwiftUI

struct LevelSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(format(value))
                    .font(.caption)
                    .foregroundStyle(.primary)
            }

            Slider(value: $value, in: range)
        }
    }
}
