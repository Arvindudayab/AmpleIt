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
    @State private var isHelpPresented: Bool = false

    @ViewBuilder
    private func songRow(_ song: Song) -> some View {
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
        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                libraryStore.addToQueue(song: song)
            } label: {
                Label("Queue", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            .tint(Color("AppAccent"))
        }
    }

    private func homeSectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.title3.weight(.semibold))
            Spacer()
            Button("See all") { selectedTab = .songs }
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .textCase(nil)
        .listRowInsets(EdgeInsets())
    }

    var body: some View {
        AppScreenContainer(
            title: currentTab.title,
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS,
            showsTrailingPlaceholder: false,
            trailingToolbar: AnyView(
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        selectedTab = .amp
                    }
                } label: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Amp")
            )
        ) {
            ZStack {
                if libraryStore.recentlyAddedSongs.isEmpty {
                    HomeEmptyState(onHelp: { isHelpPresented = true })
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                List {
                    if !libraryStore.recentlyAddedSongs.isEmpty {
                        Section {
                            ForEach(libraryStore.recentlyAddedSongs) { song in
                                songRow(song)
                            }
                        } header: {
                            homeSectionHeader("Recently Added")
                        }
                    }
                    
                    if !libraryStore.recentlyPlayedSongs.isEmpty {
                        Section {
                            ForEach(libraryStore.recentlyPlayedSongs) { song in
                                songRow(song)
                            }
                        } header: {
                            homeSectionHeader("Recently Played")
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .listSectionSpacing(20)
                .safeAreaPadding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)

                if let song = actionsSong {
                    SongActionsOverlay(
                        song: song,
                        isPresented: Binding(
                            get: { actionsSong != nil },
                            set: { newValue in if !newValue { actionsSong = nil } }
                        ),
                        onEdit: { editingSong = song },
                        onDuplicate: { libraryStore.duplicate(song: song) },
                        onAddToQueue: { libraryStore.addToQueue(song: song) },
                        onAddToPlaylist: { /* handled inside overlay sheet */ },
                        onDelete: { libraryStore.delete(songID: song.id) }
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
            .environmentObject(libraryStore)
        }
        .fullScreenCover(isPresented: $isHelpPresented) {
            OnboardingView(onClose: { isHelpPresented = false })
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
    let onHelp: () -> Void

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

            Button(action: onHelp) {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.primary.opacity(0.18), Color.primary.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(.horizontal, 40)
    }
}

