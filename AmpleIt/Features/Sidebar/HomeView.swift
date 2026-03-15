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
                if libraryStore.recentlyAddedSongs.isEmpty {
                    HomeEmptyState()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        if !libraryStore.recentlyPlayedSongs.isEmpty {
                            HomeSection(title: "Recently Played") {
                                VStack(spacing: 10) {
                                    ForEach(libraryStore.recentlyPlayedSongs) { song in
                                        SongCardRow(
                                            song: song,
                                            isNowPlaying: song.id == currentPlayingSongID,
                                            onTap: { onPlaySong(song) },
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

                        if !libraryStore.recentlyAddedSongs.isEmpty {
                            HomeSection(title: "Recently Added") {
                                VStack(spacing: 10) {
                                    ForEach(libraryStore.recentlyAddedSongs) { song in
                                        SongCardRow(
                                            song: song,
                                            isNowPlaying: song.id == currentPlayingSongID,
                                            onTap: { onPlaySong(song) },
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

// MARK: - Empty State

private struct HomeEmptyState: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "music.note.house")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color.primary.opacity(0.20))

            Text("Your Library is Empty")
                .font(.system(size: 18, weight: .semibold))

            Text("Head to Songs to import your first track.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
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
