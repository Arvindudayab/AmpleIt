//
//  PlaylistsView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.
//

import SwiftUI

private struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ArtworkPlaceholder(seed: playlist.id.uuidString)
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text(playlist.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text("\(playlist.count) songs")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }
}


struct PlaylistsView: View {
    @Binding var isSidebarOpen: Bool
    let chromeNS: Namespace.ID
    let currentTab: AppTab
    @Binding var isBackButtonActive: Bool

    private let gridSpacing: CGFloat = 18
    private let rowSpacing: CGFloat = 26
    
    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: gridSpacing),
            GridItem(.flexible(), spacing: gridSpacing)
        ]
    }

    var body: some View {
        AppScreenContainer(
            title: currentTab.title,
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS
        ) {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: rowSpacing) {
                        ForEach(MockData.playlists) { playlist in
//                            PlaylistCard(playlist: playlist)
                            NavigationLink {
                                PlaylistDetailView(
                                    playlist: playlist,
                                    isSidebarOpen: $isSidebarOpen,
                                    chromeNS: chromeNS,
                                    isBackButtonActive: $isBackButtonActive
                                )
                            } label: {
                                PlaylistCard(playlist: playlist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppLayout.horizontalPadding)
                    .padding(.top, 12)
                    // extra space so the last row isn't covered by the mini-player
                    .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)
                }

                FloatingAddButton(systemImage: "plus") {
                    print("Create playlist")
                }
                .padding(.trailing, AppLayout.horizontalPadding)
                .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing)
            }
        }
    }
}

func playlistSongs(for playlist: Playlist) -> [Song] {
    // Demo mapping until playlists are backed by real data.
    // Use a deterministic shuffle based on the playlist id so it stays stable.
    var generator = SeededGenerator(seed: UInt64(abs(playlist.id.uuidString.hashValue)))
    let shuffled = MockData.songs.shuffled(using: &generator)
    let n = max(0, min(playlist.count, shuffled.count))
    return Array(shuffled.prefix(n))
}


#Preview("Playlists") {
    PlaylistsPreviewWrapper()
}

private struct PlaylistsPreviewWrapper: View {
    @State private var isSidebarOpen: Bool = false
    @State private var isBackButtonActive: Bool = false
    @Namespace private var chromeNS

    var body: some View {
        PlaylistsView(
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS,
            currentTab: .playlists,
            isBackButtonActive: $isBackButtonActive
        )
    }
}
