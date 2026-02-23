//
//  PlaylistsView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.
//

import SwiftUI

private struct PlaylistCard: View {
    let playlist: Playlist
    let artwork: Image?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.primary.opacity(0.06))

                if let artwork {
                    artwork
                        .resizable()
                        .scaledToFill()
                } else {
                    ArtworkPlaceholder(seed: playlist.id.uuidString)
                }
            }
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
    @State private var playlists: [Playlist] = []
    @State private var createdPlaylists: [CreatedPlaylist] = []
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
        let base = playlists.map { PlaylistItem(playlist: $0, artwork: nil) }
        let created = createdPlaylists.map {
            PlaylistItem(
                playlist: Playlist(id: $0.id, name: $0.name, count: 0),
                artwork: $0.artwork
            )
        }
        return base + created
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
            createPlaylistForm
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var createPlaylistForm: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showArtworkOverlay = true
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.primary.opacity(0.06))

                                Group {
                                    if let newPlaylistArtwork {
                                        newPlaylistArtwork
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        ArtworkPlaceholder(seed: "new-playlist")
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay {
                                    if showArtworkOverlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.black.opacity(0.25))
                                            .onTapGesture {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    showArtworkOverlay = false
                                                }
                                            }

                                        Button {
                                            if newPlaylistArtwork == nil {
                                                newPlaylistArtwork = Image(systemName: "photo")
                                            } else {
                                                newPlaylistArtwork = nil
                                            }
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                showArtworkOverlay = false
                                            }
                                        } label: {
                                            Text("Replace")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.black.opacity(0.35))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Replace artwork")
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color("AppBackground"))
                } header: {
                    Text("Artwork")
                }

                Section {
                    TextField("Playlist name", text: $newPlaylistName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(.primary.opacity(0.10), lineWidth: 1)
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color("AppBackground"))
                } header: {
                    Text("Name")
                }

                Section {
                    Button {
                        createPlaylist()
                    } label: {
                        Text("Create")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color("AppAccent").opacity(0.25))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color("AppAccent").opacity(0.6), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .listRowBackground(Color("AppBackground"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle("Create Playlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                            isCreatePlaylistPresented = false
                            showArtworkOverlay = false
                        }
                    }
                }
            }
        }
        .presentationBackground(Color("AppBackground"))
    }

    private func createPlaylist() {
        let trimmedName = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        createdPlaylists.append(
            CreatedPlaylist(
                id: UUID(),
                name: trimmedName,
                artwork: newPlaylistArtwork
            )
        )
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
        playlists.removeAll { selectedPlaylistIDs.contains($0.id) }
        createdPlaylists.removeAll { selectedPlaylistIDs.contains($0.id) }
        selectedPlaylistIDs.removeAll()
        isSelecting = false
    }
}

private struct PlaylistItem: Identifiable {
    let playlist: Playlist
    let artwork: Image?

    var id: UUID { playlist.id }
}

private struct CreatedPlaylist: Identifiable {
    let id: UUID
    let name: String
    let artwork: Image?
}

private struct PlaylistCardSelectable: View {
    let playlist: Playlist
    let artwork: Image?
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PlaylistCard(playlist: playlist, artwork: artwork)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(isSelected ? Color("AppAccent") : Color.primary.opacity(0.12), lineWidth: 2)
                )

            ZStack {
                Circle()
                    .fill(isSelected ? Color("AppAccent") : Color.primary.opacity(0.12))
                Image(systemName: isSelected ? "checkmark" : "circle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isSelected ? Color("AppBackground") : Color.primary.opacity(0.6))
            }
            .frame(width: 24, height: 24)
            .padding(8)
        }
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
    }
}
