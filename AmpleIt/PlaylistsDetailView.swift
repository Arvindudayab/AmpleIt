//
//  PlaylistsDetailView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 1/9/26.
//

import SwiftUI

// This view is referenced by PlaylistsView.swift
struct PlaylistDetailView: View {
    let playlist: Playlist
    @Binding var isSidebarOpen: Bool
    let chromeNS: Namespace.ID
    @Binding var isBackButtonActive: Bool

    @State private var songs: [Song] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AppScreenContainer(
            title: "",
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS,
            wrapInNavigationStack: false,
            showsSidebarButton: false
        ) {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 18) {
                        // Cover
                        ArtworkPlaceholder(seed: playlist.id.uuidString)
                            .aspectRatio(1, contentMode: .fill)
                            .frame(maxWidth: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.top, 18)

                        // Title (in-content).
                        Text(playlist.name)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding(.top, 4)

                        // Play / Shuffle buttons
                        HStack(spacing: 14) {
                            PlaylistActionButton(title: "Play", systemImage: "play.fill") {
                                print("Play \(playlist.name)")
                            }

                            PlaylistActionButton(title: "Shuffle", systemImage: "shuffle") {
                                print("Shuffle \(playlist.name)")
                                songs.shuffle()
                            }
                        }
                        .padding(.horizontal, AppLayout.horizontalPadding)
                        .padding(.top, 2)

                        // Track list
                        VStack(spacing: 0) {
                            ForEach(songs) { song in
                                PlaylistTrackRow(song: song)
                                Divider().opacity(0.5)
                            }

                            //PlaylistAddMusicRow()
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, AppLayout.horizontalPadding)

                        // Footer metadata
                        HStack {
                            Text("\(songs.count) song\(songs.count == 1 ? "" : "s"), \(estimatedMinutes) minutes")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, AppLayout.horizontalPadding)
                        .padding(.top, 6)
                        .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)
                    }
                }

                FloatingAddButton(systemImage: "plus") {
                    print("Create playlist")
                }
                .padding(.trailing, AppLayout.horizontalPadding)
                .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing)
            }
            
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            isBackButtonActive = false
                        }
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            //.background(.ultraThinMaterial, in: Circle())
//                            .overlay(
//                                Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1)
//                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                }
            }
            .tint(Color.primary)
            .onAppear {
                isBackButtonActive = true
            }
            .onDisappear {
                isBackButtonActive = false
            }
            .task {
                songs = Self.makeSongs(for: playlist)
            }
        }
    }

    private var estimatedMinutes: Int {
        // Simple estimate since Song doesn’t yet have duration
        max(1, songs.count * 3)
    }

    // MARK: - Demo song source (deterministic until you have real playlist storage)
    private static func makeSongs(for playlist: Playlist) -> [Song] {
        var rng = SeededGenerator(seed: UInt64(abs(playlist.id.uuidString.hashValue)))
        let shuffled = MockData.songs.shuffled(using: &rng)
        let n = max(0, min(playlist.count, shuffled.count))
        return Array(shuffled.prefix(n))
    }
}

private struct PlaylistActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(0.04),
                                Color("AppAccent").opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PlaylistTrackRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 14) {
            ArtworkPlaceholder(seed: song.id.uuidString)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 12)
    }
}

#Preview("Playlist Detail") {
    PlaylistDetailPreviewWrapper()
}

private struct PlaylistDetailPreviewWrapper: View {
    @State private var isSidebarOpen: Bool = false
    @Namespace private var chromeNS
    @State private var isBackButtonActive: Bool = true

    var body: some View {
        NavigationStack {
            PlaylistDetailView(
                playlist: MockData.playlists.first!,
                isSidebarOpen: $isSidebarOpen,
                chromeNS: chromeNS,
                isBackButtonActive: $isBackButtonActive
            )
        }
    }
}
