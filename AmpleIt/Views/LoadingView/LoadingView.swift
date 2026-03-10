import SwiftUI

struct LoadingView: View {
    @State private var pulseScale: CGFloat = 0.94
    @State private var ripples: [UUID] = []

    private let coreSize: CGFloat = 136
    private let pulseDuration: Double = 0.5
    private let settleDuration: Double = 0.56
    private let rippleDuration: Double = 1.9

    var body: some View {
        GeometryReader { geometry in
            let maxRippleScale = rippleScale(for: geometry.size)

            ZStack {
                LinearGradient(
                    colors: [
                        Color("AppBackground"),
                        Color("AppAccent").opacity(0.18),
                        Color("AppBackground")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ZStack {
                    ForEach(ripples, id: \.self) { rippleID in
                        LoadingRippleView(
                            rippleID: rippleID,
                            baseSize: coreSize,
                            maxScale: maxRippleScale,
                            duration: rippleDuration
                        )
                    }

                    Circle()
                        .fill(Color("AppAccent").opacity(0.25))
                        .frame(width: coreSize, height: coreSize)
                        .scaleEffect(pulseScale * 1.02)
                        .blur(radius: 8)

                    Circle()
                        .strokeBorder(Color("AppAccent").opacity(0.45), lineWidth: 1)
                        .frame(width: 124, height: 124)
                        .scaleEffect(pulseScale)

                    Image("SoundAlphaV1")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.primary)
                        .padding(26)
                        .frame(width: 112, height: 112)
                        .scaleEffect(pulseScale)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .task {
                await runBeatLoop()
            }
        }
    }

    private func rippleScale(for size: CGSize) -> CGFloat {
        let screenDiagonal = sqrt((size.width * size.width) + (size.height * size.height))
        return max(2.2, (screenDiagonal / coreSize) * 1.15)
    }

    @MainActor
    private func emitRipple() {
        let id = UUID()
        ripples.append(id)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(rippleDuration))
            ripples.removeAll { $0 == id }
        }
    }

    @MainActor
    private func runBeatLoop() async {
        while !Task.isCancelled {
            emitRipple()
            withAnimation(.easeOut(duration: pulseDuration)) {
                pulseScale = 1.1
            }
            try? await Task.sleep(for: .seconds(pulseDuration))

            withAnimation(.easeInOut(duration: settleDuration)) {
                pulseScale = 0.94
            }
            try? await Task.sleep(for: .seconds(settleDuration))
        }
    }
}

private struct LoadingRippleView: View {
    let rippleID: UUID
    let baseSize: CGFloat
    let maxScale: CGFloat
    let duration: Double

    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 0.55

    var body: some View {
        Circle()
            .stroke(Color("AppAccent").opacity(opacity), lineWidth: 1.2)
            .frame(width: baseSize, height: baseSize)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    scale = maxScale
                    opacity = 0
                }
            }
    }
}

#Preview("Loading") {
    LoadingView()
}
