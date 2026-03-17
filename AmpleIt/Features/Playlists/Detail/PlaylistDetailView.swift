//
//  PlaylistsDetailView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 1/9/26.
//

import SwiftUI
import PhotosUI
import UIKit

// This view is referenced by PlaylistsView.swift
struct PlaylistDetailView: View {
    let playlist: Playlist
    @Binding var isSidebarOpen: Bool
    let chromeNS: Namespace.ID
    let currentPlayingSongID: UUID?
    let onPlaySong: (Song) -> Void
    @Binding var isBackButtonActive: Bool
    @EnvironmentObject private var libraryStore: LibraryStore

    @State private var showArtworkOverlay: Bool = false
    @State private var selectedArtworkItem: PhotosPickerItem? = nil
    @State private var isArtworkPickerPresented: Bool = false
    @State private var isAddSongsPresented: Bool = false
    @State private var isSelecting: Bool = false
    @State private var selectedTrackIDs: Set<UUID> = []
    @State private var isRemoveConfirmationPresented: Bool = false
    @State private var isRenameAlertPresented: Bool = false
    @State private var renameText: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AppScreenContainer(
            title: "",
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS,
            wrapInNavigationStack: false,
            showsSidebarButton: false,
            showsTrailingPlaceholder: false
        ) {
            ZStack(alignment: .bottomTrailing) {
                List {
                    // Cover
                    playlistCoverSection
                        .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    // Title
                    Text(playlist.name)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(EdgeInsets(top: 12, leading: AppLayout.horizontalPadding, bottom: 0, trailing: AppLayout.horizontalPadding))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    // Play / Shuffle buttons
                    HStack(spacing: 14) {
                        PlaylistActionButton(title: "Play", systemImage: "play.fill") { playPlaylist() }
                            .disabled(currentSongs.isEmpty)
                        PlaylistActionButton(title: "Shuffle", systemImage: "shuffle") { shufflePlaylist() }
                            .disabled(currentSongs.isEmpty)
                    }
                    .listRowInsets(EdgeInsets(top: 14, leading: AppLayout.horizontalPadding, bottom: 8, trailing: AppLayout.horizontalPadding))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    // Track rows or empty state
                    if currentSongs.isEmpty {
                        VStack(spacing: 8) {
                            Text("No songs yet.")
                                .font(.subheadline.weight(.semibold))
                            Text("Add songs to start building this playlist.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(currentSongs) { song in
                            PlaylistTrackRow(
                                song: song,
                                isNowPlaying: song.id == currentPlayingSongID,
                                onTap: { onPlaySong(song) },
                                onAddToQueue: { libraryStore.addToQueue(song: song) },
                                onRemoveFromPlaylist: { libraryStore.removeSong(songID: song.id, from: playlist.id) },
                                isSelecting: isSelecting,
                                isSelected: selectedTrackIDs.contains(song.id),
                                onSelectToggle: { toggleTrackSelection(for: song.id) }
                            )
                            .listRowInsets(EdgeInsets(top: 0, leading: AppLayout.horizontalPadding, bottom: 0, trailing: AppLayout.horizontalPadding))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.visible)
                            .listRowSeparatorTint(.primary.opacity(0.10))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    libraryStore.removeSong(songID: song.id, from: playlist.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .tint(.red)
                                Button {
                                    libraryStore.addToQueue(song: song)
                                } label: {
                                    Image(systemName: "text.line.first.and.arrowtriangle.forward")
                                }
                                .tint(Color("AppAccent"))
                            }
                        }
                    }

                    // Footer
                    HStack {
                        Text("\(currentSongs.count) song\(currentSongs.count == 1 ? "" : "s"), \(estimatedMinutes) minutes")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: AppLayout.horizontalPadding, bottom: 0, trailing: AppLayout.horizontalPadding))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .safeAreaPadding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)

                if !isSelecting {
                    FloatingAddButton(systemImage: "plus") {
                        isAddSongsPresented = true
                    }
                    .padding(.trailing, AppLayout.horizontalPadding)
                    .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing)
                }

                if isSelecting {
                    Button {
                        isRemoveConfirmationPresented = true
                    } label: {
                        Text("Remove (\(selectedTrackIDs.count))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(.red))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedTrackIDs.isEmpty)
                    .padding(.horizontal, AppLayout.horizontalPadding)
                    .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
                }
            }

            .navigationBarBackButtonHidden(true)
            .simultaneousGesture(backSwipeGesture)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        handleBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isSelecting {
                        Button("Done") {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                isSelecting = false
                                selectedTrackIDs.removeAll()
                            }
                        }
                    } else {
                        Menu {
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                    isSelecting = true
                                }
                            } label: {
                                Label("Select Songs", systemImage: "checkmark.circle")
                            }
                            .disabled(currentSongs.isEmpty)

                            Button {
                                renameText = playlist.name
                                isRenameAlertPresented = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }

                            Divider()

                            Button {
                                for song in currentSongs {
                                    libraryStore.addToQueue(song: song)
                                }
                            } label: {
                                Label("Queue Playlist", systemImage: "text.line.first.and.arrowtriangle.forward")
                            }
                            .disabled(currentSongs.isEmpty)

                            Button {
                                showArtworkOverlay = false
                                isArtworkPickerPresented = true
                            } label: {
                                Label("Replace Cover", systemImage: "photo")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                        }
                        .accessibilityLabel("Playlist actions")
                    }
                }

            }
            .tint(Color.primary)
            .onAppear {
                isBackButtonActive = true
            }
            .onDisappear {
                isBackButtonActive = false
                showArtworkOverlay = false
                isSelecting = false
                selectedTrackIDs.removeAll()
            }
            .photosPicker(
                isPresented: $isArtworkPickerPresented,
                selection: $selectedArtworkItem,
                matching: .images
            )
            .sheet(isPresented: $isAddSongsPresented) {
                AddSongsToPlaylistSheet(
                    songs: availableLibrarySongs,
                    onAdd: addSongsToPlaylist,
                    onCancel: {}
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: selectedArtworkItem) { _, item in
                Task {
                    guard let item,
                          let data = try? await item.loadTransferable(type: Data.self),
                          let artwork = ArtworkAsset(data: data) else { return }
                    await MainActor.run {
                        libraryStore.setPlaylistArtwork(artwork, for: playlist.id)
                    }
                }
            }
            .confirmationDialog(
                "Remove selected songs?",
                isPresented: $isRemoveConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    removeSelectedSongs()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("These songs will be removed from this playlist.")
            }
            .alert("Rename Playlist", isPresented: $isRenameAlertPresented) {
                TextField("Name", text: $renameText)
                Button("Rename") {
                    libraryStore.renamePlaylist(id: playlist.id, name: renameText)
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                guard value.startLocation.x < 28 else { return }
                guard value.translation.width > 100 else { return }
                guard abs(value.translation.height) < 60 else { return }
                handleBack()
            }
    }

    private func handleBack() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            isBackButtonActive = false
        }
        dismiss()
    }

    private var playlistCoverSection: some View {
        Button {
            // First tap reveals the overlay (Replace prompt). Actual replacement happens when
            // the user taps the "Replace" button in the overlay.
            withAnimation(.easeInOut(duration: 0.15)) {
                showArtworkOverlay = true
            }
        } label: {
            ZStack {
                // Base artwork
                Group {
                    if let artworkImage = libraryStore.artwork(for: playlist.id)?.image {
                        artworkImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 320, height: 320)
                            .clipped()
                    } else {
                        ArtworkPlaceholder(seed: playlist.id.uuidString)
                    }
                }
                .frame(width: 320, height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                // Overlay shown only after tap
                if showArtworkOverlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.28))
                        .frame(width: 320, height: 320)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showArtworkOverlay = false
                            }
                        }

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showArtworkOverlay = false
                        }
                        isArtworkPickerPresented = true
                    } label: {
                        Text("Replace")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(Color.black.opacity(0.38))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Replace playlist cover")
    }

    private var estimatedMinutes: Int {
        // Simple estimate since Song doesn't yet have duration
        max(1, currentSongs.count * 3)
    }

    private var currentSongs: [Song] {
        libraryStore.songs(in: playlist.id)
    }

    private var availableLibrarySongs: [Song] {
        let existingSongIDs = Set(libraryStore.songs(in: playlist.id).map(\.id))
        return libraryStore.librarySongs.filter { !existingSongIDs.contains($0.id) }
    }

    private func addSongsToPlaylist(_ selectedSongIDs: Set<UUID>) {
        guard !selectedSongIDs.isEmpty else { return }
        let songsByID = Dictionary(uniqueKeysWithValues: libraryStore.librarySongs.map { ($0.id, $0) })
        for songID in selectedSongIDs {
            guard let song = songsByID[songID] else { continue }
            libraryStore.addSong(song, to: playlist.id)
        }
    }

    // Plays the first song in the playlist and loads the rest into the queue.
    private func playPlaylist() {
        guard let first = currentSongs.first else { return }
        libraryStore.replaceQueue(with: Array(currentSongs.dropFirst()))
        onPlaySong(first)
    }

    // Shuffles the playlist into the queue without altering the displayed order.
    private func shufflePlaylist() {
        guard !currentSongs.isEmpty else { return }
        var shuffled = currentSongs.shuffled()
        let first = shuffled.removeFirst()
        libraryStore.replaceQueue(with: shuffled)
        onPlaySong(first)
    }

    private func toggleTrackSelection(for id: UUID) {
        if selectedTrackIDs.contains(id) {
            selectedTrackIDs.remove(id)
        } else {
            selectedTrackIDs.insert(id)
        }
    }

    private func removeSelectedSongs() {
        for id in selectedTrackIDs {
            libraryStore.removeSong(songID: id, from: playlist.id)
        }
        selectedTrackIDs.removeAll()
        isSelecting = false
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
                playlist: Playlist(id: UUID(), name: "Workout Mix", count: 0),
                isSidebarOpen: $isSidebarOpen,
                chromeNS: chromeNS,
                currentPlayingSongID: nil,
                onPlaySong: { _ in },
                isBackButtonActive: $isBackButtonActive
            )
            .environmentObject(LibraryStore())
        }
    }
}
