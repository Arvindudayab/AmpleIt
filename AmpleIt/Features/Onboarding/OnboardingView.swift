import SwiftUI
import UIKit

// MARK: - Data Model

struct OnboardingPanel {
    let screenshotImageName: String
    let title: String
    let description: String
    let tip: String?
}

extension OnboardingPanel {
    static let all: [OnboardingPanel] = [
        .init(
            screenshotImageName: "Onboarding_Home",
            title: "Welcome to AmpleIt",
            description: "Your personal music player with powerful per-song customization. Browse recently added and recently played tracks right from Home.",
            tip: "Tap ··· on any song card to access quick actions like Edit, Queue, and Add to Playlist."
        ),
        .init(
            screenshotImageName: "Onboarding_Songs",
            title: "Your Song Library",
            description: "Browse and search all your tracks in one place. Use the + button to import audio from your device as an MP3 or WAV file.",
            tip: "Tap 'Select' in the top-right to choose and delete multiple songs at once."
        ),
        .init(
            screenshotImageName: "Onboarding_SongEdit",
            title: "Customize Every Track",
            description: "Tap ··· on any song and choose Edit to open the Song Editor. Adjust speed, reverb, bass, mid, and treble — all saved individually per song.",
            tip: "Pick a preset like Warm, Bass Boost, or Lo-Fi to apply a starting point quickly."
        ),
        .init(
            screenshotImageName: "Onboarding_Playlists",
            title: "Create Playlists",
            description: "Organize your music into playlists with custom cover artwork. Tap + to create one, then add songs from your library.",
            tip: "Tap 'Select' to choose and delete multiple playlists at once."
        ),
        .init(
            screenshotImageName: "Onboarding_PlaylistDetail",
            title: "Play & Shuffle Playlists",
            description: "Open a playlist to see all its tracks. Hit Play to start in order or Shuffle to randomize — both load the full playlist into your queue.",
            tip: "Tap ··· to rename the playlist, select songs to remove, or replace the cover art."
        ),
        .init(
            screenshotImageName: "Onboarding_Presets",
            title: "Presets",
            description: "Create and manage reusable EQ profiles from the Presets tab in the sidebar. Dial in speed, pitch, reverb, bass, mid, and treble — then apply any preset instantly when editing a song.",
            tip: "Built-in presets like Warm, Bass Boost, and Lo-Fi are always available as a starting point."
        ),
        .init(
            screenshotImageName: "Onboarding_Player",
            title: "The Player",
            description: "Tap any song or the mini-player to open the full-screen player. Skip tracks, toggle play/pause, and peek at your upcoming queue.",
            tip: "Swipe down anywhere on the player to collapse it back to the mini-player."
        ),
        .init(
            screenshotImageName: "Onboarding_Jam",
            title: "Jam Mode",
            description: "Tap the waveform icon in the player to enter Jam Mode — a full-screen, beat-reactive visual that pulses with the music. See the song title, artist, and detected BPM at a glance.",
            tip: "Swipe down to close Jam Mode and return to the player."
        ),
        .init(
            screenshotImageName: "Onboarding_Amp",
            title: "Meet Amp",
            description: "Amp is your built-in AI music assistant. Ask for EQ tips, creating playlists and queues, or help finding the right sound for any track.",
            tip: "Access Amp from the sidebar menu or the top right of the home menu."
        ),
    ]
}

// MARK: - Main View

struct OnboardingView: View {
    let onClose: () -> Void
    @State private var currentPage: Int = 0
    @State private var fullscreenImageName: String? = nil

    private var isLastPage: Bool { currentPage == OnboardingPanel.all.count - 1 }

    var body: some View {
        ZStack(alignment: .top) {
            Color("AppBackground").ignoresSafeArea()

            // Paged panels — pushed down to clear the dismiss handle
            TabView(selection: $currentPage) {
                ForEach(OnboardingPanel.all.indices, id: \.self) { index in
                    OnboardingPanelView(
                        panel: OnboardingPanel.all[index],
                        isLast: index == OnboardingPanel.all.count - 1,
                        onGetStarted: onClose,
                        onImageTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            fullscreenImageName = OnboardingPanel.all[index].screenshotImageName
                        }
                    }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .padding(.top, 48)

            // Close button — top trailing
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color.primary.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, AppLayout.horizontalPadding)
            }
            .padding(.top, 10)

            // Zoomed image overlay
            if let imageName = fullscreenImageName, let uiImage = UIImage(named: imageName) {
                ZoomedImageOverlay(image: uiImage) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        fullscreenImageName = nil
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(100)
            }
        }
        .simultaneousGesture(fullscreenImageName == nil ? dismissGesture : nil)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: fullscreenImageName)
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .global)
            .onEnded { value in
                let isDownward = value.translation.height > 90
                let isMostlyVertical = abs(value.translation.height) > abs(value.translation.width)
                guard isDownward, isMostlyVertical else { return }
                onClose()
            }
    }
}

// MARK: - Panel View

private struct OnboardingPanelView: View {
    let panel: OnboardingPanel
    let isLast: Bool
    let onGetStarted: () -> Void
    let onImageTap: () -> Void

    @State private var rainbowRotation: Double = 0

    private var rainbowGradient: AngularGradient {
        AngularGradient(
            colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red],
            center: .center,
            angle: .degrees(rainbowRotation)
        )
    }

    // iPhone screen aspect ratio (portrait)
    private let phoneAspect: CGFloat = 393.0 / 852.0

    private var shotHeight: CGFloat {
        min(UIScreen.main.bounds.height * 0.55, 410)
    }
    private var shotWidth: CGFloat {
        shotHeight * phoneAspect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
                // Large portrait screenshot, centered at top
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    screenshotArea(width: shotWidth, height: shotHeight)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                onImageTap()
                            }
                        }
                    Spacer(minLength: 0)
                }
                .padding(.top, 8)

                Spacer()

                // Text content pinned to bottom, above page-dot indicator
                VStack(alignment: .leading, spacing: 8) {
                    Text(panel.title)
                        .font(.system(size: 22, weight: .bold))

                    Text(panel.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let tip = panel.tip {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.primary)
                                .padding(.top, 2)
                            Text(tip)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color("AppAccent").opacity(0.10))
                        )
                        .padding(.top, 4)
                    }

                    if isLast {
                        Button(action: onGetStarted) {
                            Text("Get Started")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color("AppAccent").opacity(0.28),
                                                    Color.primary.opacity(0.06)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(Color("AppAccent").opacity(0.55), lineWidth: 1)
                                        .strokeBorder(rainbowGradient, lineWidth: 1)
                                )
                                .shadow(color: .red.opacity(0.25), radius: 8, x: 0, y: 0)
                                .shadow(color: .blue.opacity(0.2), radius: 12, x: 0, y: 0)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)

                // Room for the TabView page-dot indicator
                Spacer(minLength: 62)
            }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rainbowRotation = 360
            }
        }
    }

    private func screenshotArea(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Subtle phone-bezel ring
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.primary.opacity(0.07))
                .frame(width: width + 10, height: height + 10)

            if let uiImage = UIImage(named: panel.screenshotImageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(.primary.opacity(0.10), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Zoomed Image Overlay

private struct ZoomedImageOverlay: View {
    let image: UIImage
    let onDismiss: () -> Void

    private let phoneAspect: CGFloat = 393.0 / 852.0

    private var imageHeight: CGFloat {
        min(UIScreen.main.bounds.height * 0.82, 680)
    }
    private var imageWidth: CGFloat {
        imageHeight * phoneAspect
    }

    var body: some View {
        ZStack {
            // Dim background — tap anywhere outside the image to dismiss
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Zoomed image card — swallows its own taps so they don't reach the background
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: imageWidth, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.45), radius: 32, x: 0, y: 12)
                .onTapGesture {}
        }
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    OnboardingView(onClose: {})
}
