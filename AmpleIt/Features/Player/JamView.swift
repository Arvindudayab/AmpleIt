import SwiftUI

struct JamView: View {
    let song: Song
    let onClose: () -> Void

    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @EnvironmentObject private var libraryStore: LibraryStore

    @State private var pulseScale: CGFloat = 0.94
    @State private var ripples: [UUID] = []
    @State private var dragOffset: CGFloat = 0

    private let coreSize: CGFloat = 136
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

                // Center cluster + song info
                VStack(spacing: 28) {
                    ZStack {
                        ForEach(ripples, id: \.self) { rippleID in
                            JamRippleView(
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

                    VStack(spacing: 5) {
                        Text(song.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(bpmLabel)
                            .font(.caption)
                            .foregroundStyle(Color.primary)
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
    }

    // MARK: - Private

    private func rippleScale(for size: CGSize) -> CGFloat {
        let diagonal = sqrt(size.width * size.width + size.height * size.height)
        return max(2.2, (diagonal / coreSize) * 1.15)
    }

    @MainActor
    private func fireBeat() {
        let id = UUID()
        ripples.append(id)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(rippleDuration))
            ripples.removeAll { $0 == id }
        }

        withAnimation(.easeOut(duration: pulseDuration)) {
            pulseScale = 1.12
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(pulseDuration))
            withAnimation(.easeInOut(duration: settleDuration)) {
                pulseScale = 0.94
            }
        }
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
