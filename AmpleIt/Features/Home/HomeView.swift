//
//  HomeView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.
//

import SwiftUI


struct HomeView: View {
    @Binding var isSidebarOpen: Bool
    @Binding var selectedTab: AppTab
    let chromeNS: Namespace.ID
    let currentTab: AppTab
    let currentPlayingSongID: UUID?
    let onPlaySong: (Song) -> Void
    @Binding var isBackButtonActive: Bool
    @EnvironmentObject private var libraryStore: LibraryStore

    private let recentlyAddedIDs = Array(MockData.songs.prefix(5)).map(\.id)
    private let recentlyPlayedIDs = Array(MockData.songs.prefix(5)).map(\.id)
    @State private var actionsSong: Song? = nil
    @State private var editingSong: Song? = nil
    @State private var isOnboardingPresented: Bool = false

    var body: some View {
        AppScreenContainer(
            title: currentTab.title,
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS,
            showsTrailingPlaceholder: false,
            trailingToolbar: AnyView(
                HelpButton {
                    isOnboardingPresented = true
                }
            )
        ) {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        HomeSection(title: "Recently Added") {
                            VStack(spacing: 10) {
                                ForEach(resolveSongs(for: recentlyAddedIDs)) { song in
                                    SongCardRow(
                                        song: song,
                                        isNowPlaying: song.id == currentPlayingSongID,
                                        onTap: {
                                            onPlaySong(song)
                                        },
                                        onMore: {
                                            withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                                                actionsSong = song
                                            }
                                        }
                                    )
                                }
                            }
                        }

                        HomeSection(title: "Recently Played") {
                            VStack(spacing: 10) {
                                ForEach(resolveSongs(for: recentlyPlayedIDs)) { song in
                                    SongCardRow(
                                        song: song,
                                        isNowPlaying: song.id == currentPlayingSongID,
                                        onTap: {
                                            onPlaySong(song)
                                        },
                                        onMore: {
                                            withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                                                actionsSong = song
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
                .safeAreaPadding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)

                if let song = actionsSong {
                    SongActionsOverlay(
                        song: song,
                        isPresented: Binding(
                            get: { actionsSong != nil },
                            set: { newValue in if !newValue { actionsSong = nil } }
                        ),
                        onEdit: {
                            editingSong = song
                        },
                        onDuplicate: {
                            libraryStore.duplicate(song: song)
                        },
                        onAddToQueue: {
                            libraryStore.addToQueue(song: song)
                        },
                        onAddToPlaylist: { /* handled inside overlay sheet */ },
                        onDelete: {
                            libraryStore.delete(songID: song.id)
                        }
                    )
                    .zIndex(50)
                }
            }
        }
        .fullScreenCover(item: $editingSong) { song in
            NavigationStack {
                SongEditView(song: song, isBackButtonActive: $isBackButtonActive) { updatedSong in
                    libraryStore.updateSong(updatedSong)
                }
            }
        }
        .fullScreenCover(isPresented: $isOnboardingPresented) {
            OnboardingView(onClose: { isOnboardingPresented = false })
        }
    }

    private func resolveSongs(for ids: [UUID]) -> [Song] {
        let byID = Dictionary(uniqueKeysWithValues: libraryStore.librarySongs.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }
}

#Preview("Home") {
    HomePreviewWrapper()
}

private struct HomePreviewWrapper: View {
    @State private var isSidebarOpen: Bool = false
    @State private var selectedTab: AppTab = .home
    @State private var isBackButtonActive: Bool = false
    @Namespace private var chromeNS

    var body: some View {
        HomeView(
            isSidebarOpen: $isSidebarOpen,
            selectedTab: $selectedTab,
            chromeNS: chromeNS,
            currentTab: .home,
            currentPlayingSongID: nil,
            onPlaySong: { _ in },
            isBackButtonActive: $isBackButtonActive
        )
        .environmentObject(LibraryStore())
    }
}

private struct HelpButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "questionmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("How to use AmpleIt")
    }
}
