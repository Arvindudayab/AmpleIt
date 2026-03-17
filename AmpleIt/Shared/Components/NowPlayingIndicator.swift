import SwiftUI

struct NowPlayingIndicator: View {
    var size: CGFloat = 12

    var body: some View {
        Image(systemName: "waveform.mid")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(Color.primary)
            .symbolEffect(.pulse.byLayer, options: .repeat(.continuous))
    }
}

#Preview("Now Playing Indicator") {
    NowPlayingIndicator()
        .padding()
}
