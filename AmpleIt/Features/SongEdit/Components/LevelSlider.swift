import SwiftUI

struct LevelSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
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

            if let step {
                Slider(value: $value, in: range, step: step)
            } else {
                Slider(value: $value, in: range)
            }
        }
    }
}

#Preview("Level Slider") {
    VStack(spacing: 20) {
        LevelSlider(title: "Speed", value: .constant(1.0), range: 0.25...4.0, step: 0.05) {
            String(format: "%.2fx", $0)
        }
        LevelSlider(title: "Bass", value: .constant(0.0), range: -12.0...12.0) {
            String(format: "%+.0f dB", $0)
        }
    }
    .padding()
}
