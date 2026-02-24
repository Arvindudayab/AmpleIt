//
//  PlaylistsView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.
//

import SwiftUI


struct PlaylistsView: View {
    @Binding var isSidebarOpen: Bool
    let chromeNS: Namespace.ID
    let currentTab: AppTab
    @Binding var isBackButtonActive: Bool
    @EnvironmentObject private var libraryStore: LibraryStore
    @State private var isCreatePlaylistPresented: Bool = false
    @State private var newPlaylistName: String = ""
    @State private var newPlaylistArtwork: Image? = nil
    @State private var showArtworkOverlay: Bool = false
    @State private var isSelecting: Bool = false
    @State private var selectedPlaylistIDs: Set<UUID> = []
    @State private var isDeleteConfirmationPresented: Bool = false

    private let gridSpacing: CGFloat = 18
    private let rowSpacing: CGFloat = 26
    
    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: gridSpacing),
            GridItem(.flexible(), spacing: gridSpacing)
        ]
    }
    
    private var allPlaylists: [PlaylistItem] {
        libraryStore.playlists.map {
            PlaylistItem(
                playlist: $0,
                artwork: libraryStore.playlistArtwork[$0.id]
            )
        }
    }
    
    var body: some View {
        AppScreenContainer(
            title: currentTab.title,
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS,
            showsTrailingPlaceholder: false,
            trailingToolbar: AnyView(
                Button(isSelecting ? "Done" : "Select") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        isSelecting.toggle()
                        if !isSelecting {
                            selectedPlaylistIDs.removeAll()
                        }
                    }
                }
                .disabled(allPlaylists.isEmpty)
            )
        ) {
            ZStack(alignment: .bottomTrailing) {
                if allPlaylists.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 36, weight: .semibold))
                        Text("No playlists yet")
                            .font(.headline.weight(.semibold))
                        Text("Create your first playlist to get started.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, AppLayout.horizontalPadding)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: rowSpacing) {
                            ForEach(allPlaylists) { item in
                                if isSelecting {
                                    PlaylistCardSelectable(
                                        playlist: item.playlist,
                                        artwork: item.artwork,
                                        isSelected: selectedPlaylistIDs.contains(item.playlist.id)
                                    )
                                    .onTapGesture {
                                        toggleSelection(for: item.playlist.id)
                                    }
                                } else {
                                    NavigationLink {
                                        PlaylistDetailView(
                                            playlist: item.playlist,
                                            isSidebarOpen: $isSidebarOpen,
                                            chromeNS: chromeNS,
                                            isBackButtonActive: $isBackButtonActive
                                        )
                                    } label: {
                                        PlaylistCard(playlist: item.playlist, artwork: item.artwork)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, AppLayout.horizontalPadding)
                        .padding(.top, 12)
                        // extra space so the last row isn't covered by the mini-player
                        .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)
                    }
                }

                if !isSelecting {
                    FloatingAddButton(systemImage: "plus") {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                            isCreatePlaylistPresented = true
                        }
                    }
                    .padding(.trailing, AppLayout.horizontalPadding)
                    .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing)
                }

                if isCreatePlaylistPresented {
                    EmptyView()
                }
            }
        }
        .toolbar {
            if isSelecting {
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        isDeleteConfirmationPresented = true
                    } label: {
                        Text("Delete (\(selectedPlaylistIDs.count))")
                    }
                    .disabled(selectedPlaylistIDs.isEmpty)
                }
            }
        }
        .confirmationDialog(
            "Delete selected playlists?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedPlaylists()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $isCreatePlaylistPresented) {
            CreatePlaylistFormSheet(
                name: $newPlaylistName,
                artwork: $newPlaylistArtwork,
                showArtworkOverlay: $showArtworkOverlay,
                onCreate: createPlaylist,
                onDone: {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isCreatePlaylistPresented = false
                        showArtworkOverlay = false
                    }
                }
            )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color("AppBackground"))
        }
    }

    private func createPlaylist() {
        let trimmedName = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        _ = libraryStore.createPlaylist(name: trimmedName, artwork: newPlaylistArtwork)
        newPlaylistName = ""
        newPlaylistArtwork = nil
        showArtworkOverlay = false
        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
            isCreatePlaylistPresented = false
        }
    }

    private func toggleSelection(for id: UUID) {
        if selectedPlaylistIDs.contains(id) {
            selectedPlaylistIDs.remove(id)
        } else {
            selectedPlaylistIDs.insert(id)
        }
    }

    private func deleteSelectedPlaylists() {
        guard !selectedPlaylistIDs.isEmpty else { return }
        libraryStore.deletePlaylists(ids: selectedPlaylistIDs)
        selectedPlaylistIDs.removeAll()
        isSelecting = false
    }
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
        .environmentObject(LibraryStore())
    }
}
