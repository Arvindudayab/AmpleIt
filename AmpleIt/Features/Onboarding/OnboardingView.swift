import SwiftUI
import UIKit

// MARK: - Data Model

struct OnboardingPanel {
    let screenshotImageName: String
    let fallbackIcon: String
    let screenshotLabel: String
    let title: String
    let description: String
    let tip: String?

    // ── Screenshot guidance (for the developer, not shown in the UI) ──────────
    // Each `screenshotImageName` maps to an image asset you add to Assets.xcassets.
    // Add them as PNG/JPEG with the names listed below, 2× or 3× resolution.
    //
    //  "Onboarding_Home"
    //      → Home tab: nav bar with AmpleIt logo, "Recently Added" section showing
    //        5 song card rows (artwork placeholder, title, artist, ellipsis button),
    //        "Recently Played" section below, mini-player floating at bottom.
    //
    //  "Onboarding_Songs"
    //      → Songs tab: search bar at top, list of song cards (one song showing
    //        the animated NowPlayingIndicator), floating + FAB visible bottom-right,
    //        Select button in top-right.
    //
    //  "Onboarding_SongEdit"
    //      → SongEditView: square artwork placeholder at top (centered), Song Name
    //        and Artist text fields below, Preset picker showing "Default", then
    //        the five level sliders (Speed, Reverb, Bass, Mid, Treble) with values.
    //
    //  "Onboarding_Playlists"
    //      → PlaylistsView: 2-column grid of playlist cards each with artwork
    //        placeholder, playlist name, and song count. Floating + FAB bottom-right.
    //
    //  "Onboarding_PlaylistDetail"
    //      → PlaylistDetailView: large square cover at top (centered), bold playlist
    //        name, Play and Shuffle action buttons side by side, then 2–3 track rows
    //        showing artwork, title, artist, and ellipsis menu button.
    //
    //  "Onboarding_Player"
    //      → SongPlayerView: full-screen view with large square artwork placeholder,
    //        song title and artist below it, static progress bar with timestamps,
    //        three playback controls (backward, play/pause, forward), Queue button
    //        bottom-right.
    //
    //  "Onboarding_Amp"
    //      → AmpView: circular Amp logo icon (gradient fill) at top, "I'm Amp, ask
    //        me anything" headline, "I can help with mixes…" subtext, two demo chat
    //        bubbles (user + Amp replies), text input bar at the bottom with send button.
}

extension OnboardingPanel {
    static let all: [OnboardingPanel] = [
        .init(
            screenshotImageName: "Onboarding_Home",
            fallbackIcon: "house.fill",
            screenshotLabel: "Home Screen",
            title: "Welcome to AmpleIt",
            description: "Your personal music player with powerful per-song customization. Browse recently added and recently played tracks right from Home.",
            tip: "Tap ··· on any song card to access quick actions like Edit, Queue, and Add to Playlist."
        ),
        .init(
            screenshotImageName: "Onboarding_Songs",
            fallbackIcon: "music.note.list",
            screenshotLabel: "Song Library",
            title: "Your Song Library",
            description: "Browse and search all your tracks in one place. Use the + button to import audio from your device (MP3, WAV) or convert from YouTube.",
            tip: "Tap 'Select' in the top-right to choose and delete multiple songs at once."
        ),
        .init(
            screenshotImageName: "Onboarding_SongEdit",
            fallbackIcon: "slider.horizontal.3",
            screenshotLabel: "Song Editor",
            title: "Customize Every Track",
            description: "Tap ··· on any song and choose Edit to open the Song Editor. Adjust speed, reverb, bass, mid, and treble — all saved individually per song.",
            tip: "Pick a preset like Warm, Bass Boost, or Lo-Fi to apply a starting point quickly."
        ),
        .init(
            screenshotImageName: "Onboarding_Playlists",
            fallbackIcon: "square.grid.2x2.fill",
            screenshotLabel: "Playlists",
            title: "Create Playlists",
            description: "Organize your music into playlists with custom cover artwork. Tap + to create one, then add songs from your library.",
            tip: "Tap 'Select' to choose and delete multiple playlists at once."
        ),
        .init(
            screenshotImageName: "Onboarding_PlaylistDetail",
            fallbackIcon: "music.note.list",
            screenshotLabel: "Playlist Detail",
            title: "Play & Shuffle Playlists",
            description: "Open a playlist to see all its tracks. Hit Play to start in order or Shuffle to randomize — both load the full playlist into your queue.",
            tip: "Tap ··· to rename the playlist, select songs to remove, or replace the cover art."
        ),
        .init(
            screenshotImageName: "Onboarding_Player",
            fallbackIcon: "play.circle.fill",
            screenshotLabel: "Full-Screen Player",
            title: "The Player",
            description: "Tap any song or the mini-player to open the full-screen player. Skip tracks, toggle play/pause, and peek at your upcoming queue.",
            tip: "Swipe down anywhere on the player to collapse it back to the mini-player."
        ),
        .init(
            screenshotImageName: "Onboarding_Amp",
            fallbackIcon: "sparkles",
            screenshotLabel: "Amp",
            title: "Meet Amp",
            description: "Amp is your built-in AI music assistant. Ask for EQ tips, mixing advice, or help finding the right sound for any track.",
            tip: "Access Amp from the sidebar menu."
        ),
    ]
}

// MARK: - Main View

struct OnboardingView: View {
    let onClose: () -> Void
    @State private var currentPage: Int = 0

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
                        onGetStarted: onClose
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .padding(.top, 48)

            // Dismiss handle: capsule pill + chevron
            VStack(spacing: 6) {
                Capsule()
                    .fill(Color.primary.opacity(0.50))
                    .frame(width: 144, height: 5)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.30))
            }
            .padding(.top, 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { onClose() }
            .accessibilityLabel("Close")
            .accessibilityAddTraits(.isButton)
        }
        .simultaneousGesture(dismissGesture)
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

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                screenshotArea
                    .frame(height: max(260, geo.size.height * 0.44))
                    .padding(.horizontal, AppLayout.horizontalPadding)

                VStack(alignment: .leading, spacing: 10) {
                    Text(panel.title)
                        .font(.system(size: 26, weight: .bold))
                        .padding(.top, 20)

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
                        .padding(10)
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
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)

                // Spacer absorbs leftover space above the page-dot indicator
                Spacer(minLength: 44)
            }
        }
    }

    private var screenshotArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("AppAccent").opacity(0.12),
                            Color.primary.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let uiImage = UIImage(named: panel.screenshotImageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                // Placeholder — visible until you add the real screenshot asset
                VStack(spacing: 14) {
                    Image(systemName: panel.fallbackIcon)
                        .font(.system(size: 46, weight: .light))
                        .foregroundStyle(Color("AppAccent").opacity(0.55))
                    Text(panel.screenshotLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Add \"\(panel.screenshotImageName)\" to Assets.xcassets")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    OnboardingView(onClose: {})
}
