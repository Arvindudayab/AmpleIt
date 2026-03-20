import SwiftUI

struct JamView: View {
    let song: Song
    let onClose: () -> Void

    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @EnvironmentObject private var libraryStore: LibraryStore

    @State private var pulseScale: CGFloat = 0.94
    @State private var ripples: [UUID] = []
    @State private var dragOffset: CGFloat = 0
    @State private var blobPhase: Bool = false
    @State private var beatGlowOpacity: Double = 0

    private let coreSize: CGFloat = 200
    private let rippleDuration: Double = 1.9
    private let pulseDuration: Double = 0.12
    private let settleDuration: Double = 0.20

    private var bpmLabel: String {
        if let bpm = libraryStore.songAnalysis[song.id]?.bpm {
            return String(format: "%.0f BPM", bpm)
        }
        return "120 BPM"
    }

    var body: some View {
        GeometryReader { geometry in
            let maxRippleScale = rippleScale(for: geometry.size)

            ZStack {
                backgroundLayer

                // Center cluster + song info — pinned to exact screen center
                VStack(spacing: 28) {
                    ZStack {
                        // Ripple rings — commented out, keeping pulse and blur
//                        ForEach(ripples, id: \.self) { rippleID in
//                            JamRippleView(
//                                rippleID: rippleID,
//                                baseSize: coreSize,
//                                maxScale: maxRippleScale,
//                                duration: rippleDuration
//                            )
//                        }

                        Circle()
                            .fill(Color("AppAccent").opacity(0.25))
                            .frame(width: coreSize, height: coreSize)
                            .scaleEffect(pulseScale * 1.02)
                            .blur(radius: 8)

                        Circle()
                            .strokeBorder(Color("AppAccent").opacity(0.45), lineWidth: 1)
                            .frame(width: 184, height: 184)
                            .scaleEffect(pulseScale)

                        Image("SoundAlphaV1")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.primary)
                            .padding(36)
                            .frame(width: 168, height: 168)
                            .scaleEffect(pulseScale)
                    }

                    VStack(spacing: 5) {
                        Text(song.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(bpmLabel)
                            .font(.caption)
                            .foregroundStyle(Color.primary)
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: 300)
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                // Dismiss button — top leading
                VStack {
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .background(Color.primary.opacity(0.08), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, AppLayout.horizontalPadding)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 12)
            }
        }
        .offset(y: dragOffset)
        .simultaneousGesture(dismissDragGesture)
        .onReceive(audioPlayer.onsetDetected) { _ in
            guard audioPlayer.isPlaying else { return }
            fireBeat()
        }
        .onAppear { blobPhase = true }
    }

    // MARK: - Private

    private func rippleScale(for size: CGSize) -> CGFloat {
        let diagonal = sqrt(size.width * size.width + size.height * size.height)
        return max(2.2, (diagonal / coreSize) * 1.15)
    }

    @MainActor
    private func fireBeat() {
        // Ripple spawning commented out — keeping pulse and glow
//        let id = UUID()
//        ripples.append(id)
//        Task { @MainActor in
//            try? await Task.sleep(for: .seconds(rippleDuration))
//            ripples.removeAll { $0 == id }
//        }

        withAnimation(.easeOut(duration: pulseDuration)) {
            pulseScale = 1.12
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(pulseDuration))
            withAnimation(.easeInOut(duration: settleDuration)) {
                pulseScale = 0.94
            }
        }

        withAnimation(.easeOut(duration: 0.10)) { beatGlowOpacity = 0.12 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.10))
            withAnimation(.easeOut(duration: 0.60)) { beatGlowOpacity = 0 }
        }
    }

    private var backgroundLayer: some View {
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

            // Blob 1 — top trailing, large drift
            Circle()
                .fill(Color("AppAccent").opacity(0.13))
                .frame(width: 320, height: 320)
                .blur(radius: 55)
                .offset(x: blobPhase ? 110 : 55, y: blobPhase ? -200 : -130)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: blobPhase)

            // Blob 2 — bottom leading, medium drift
            Circle()
                .fill(Color("AppAccent").opacity(0.09))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: blobPhase ? -115 : -55, y: blobPhase ? 190 : 120)
                .animation(.easeInOut(duration: 11).repeatForever(autoreverses: true).delay(2.5), value: blobPhase)

            // Blob 3 — center, slow breath
            Circle()
                .fill(Color.primary.opacity(0.035))
                .frame(width: 240, height: 240)
                .blur(radius: 45)
                .offset(x: blobPhase ? 30 : -30, y: blobPhase ? 50 : -50)
                .animation(.easeInOut(duration: 14).repeatForever(autoreverses: true).delay(5), value: blobPhase)

            // Beat glow — radial flash on drum onset
            Circle()
                .fill(Color("AppAccent").opacity(beatGlowOpacity))
                .frame(width: 520, height: 520)
                .blur(radius: 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var dismissDragGesture: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .global)
            .onChanged { value in
                let dy = value.translation.height
                if dy > 0 {
                    dragOffset = min(dy, 90 + (dy - 90) * 0.15)
                }
            }
            .onEnded { value in
                let isDownward = value.translation.height > 90
                let isMostlyVertical = abs(value.translation.height) > abs(value.translation.width)
                if isDownward && isMostlyVertical {
                    onClose()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

// MARK: - Ripple Ring

private struct JamRippleView: View {
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

// MARK: - Preview

#Preview("Jam View") {
    let store = LibraryStore.preview
    JamView(
        song: MockData.songs.first!,
        onClose: {}
    )
    .environmentObject(store)
    .environmentObject(AudioPlayerService())
}
