//
//  SongLibraryView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct SongLibraryView: View {
    @Binding var isSidebarOpen: Bool
    @Binding var isBackButtonActive: Bool
    let chromeNS: Namespace.ID
    let currentTab: AppTab
    let currentPlayingSongID: UUID?
    let onPlaySong: (Song) -> Void
    @EnvironmentObject private var libraryStore: LibraryStore

    @State private var searchText: String = ""
    @State private var actionsSong: Song? = nil
    @State private var editingSong: Song? = nil
    @State private var importedDraftSong: Song? = nil
    @State private var isAddMenuPresented: Bool = false
    @State private var isYTUploadActive: Bool = false
    @State private var isDeviceImporterPresented: Bool = false
    @State private var importAlertMessage: String?
    @State private var isSelecting = false
    @State private var selectedSongIDs: Set<UUID> = []
    @State private var isDeleteConfirmationPresented = false

    private static let allowedAudioTypes: [UTType] = [
        UTType(filenameExtension: "mp3") ?? .audio,
        UTType(filenameExtension: "wav") ?? .audio
    ]

    private var filteredSongs: [Song] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return libraryStore.librarySongs
        }
        let q = searchText.lowercased()
        return libraryStore.librarySongs.filter {
            $0.title.lowercased().contains(q) || $0.artist.lowercased().contains(q)
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
                            selectedSongIDs.removeAll()
                        }
                    }
                }
                .disabled(libraryStore.librarySongs.isEmpty)
            )
        ) {
            ZStack(alignment: .bottomTrailing) {
                if libraryStore.librarySongs.isEmpty {
                    SongLibraryEmptyState()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if filteredSongs.isEmpty {
                            SongLibraryNoResults(query: searchText)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(filteredSongs) { song in
                                Group {
                                    if isSelecting {
                                        selectableSongRow(song)
                                    } else {
                                        SongCardRow(
                                            song: song,
                                            isNowPlaying: song.id == currentPlayingSongID,
                                            onTap: {
                                                onPlaySong(song)
                                            },
                                            onEdit: { /* later */ },
                                            onAddToPlaylist: { /* later */ },
                                            onDelete: { /* later */ },
                                            onMore: {
                                                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                                                    actionsSong = song
                                                }
                                            }
                                        )
                                    }
                                }
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(
                                    top: AppLayout.verticalRowSpacing,
                                    leading: AppLayout.horizontalPadding,
                                    bottom: AppLayout.verticalRowSpacing,
                                    trailing: AppLayout.horizontalPadding
                                ))
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .safeAreaPadding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)
                }

                if !isSelecting {
                    FloatingAddButton {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                            isAddMenuPresented.toggle()
                        }
                    }
                    .padding(.trailing, AppLayout.horizontalPadding)
                    .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing)
                }
                
                if isAddMenuPresented {
                    addMenuOverlay
                        .zIndex(40)
                }

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
                    .zIndex(50) // ensure it's above list + add button + mini-player
                }

            }
            .navigationDestination(isPresented: $isYTUploadActive) {
                YTUploadView(
                    isSidebarOpen: $isSidebarOpen,
                    chromeNS: chromeNS,
                    isBackButtonActive: $isBackButtonActive
                )
            }
        }
        .toolbar {
            if isSelecting {
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        isDeleteConfirmationPresented = true
                    } label: {
                        Text("Delete (\(selectedSongIDs.count))")
                    }
                    .disabled(selectedSongIDs.isEmpty)
                }
            }
        }
        .confirmationDialog(
            "Delete selected songs?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedSongs()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the selected songs from your library, queue, and playlists.")
        }
        .fileImporter(
            isPresented: $isDeviceImporterPresented,
            allowedContentTypes: Self.allowedAudioTypes,
            allowsMultipleSelection: false,
            onCompletion: handleDeviceImport
        )
        .alert("Upload Failed", isPresented: importAlertIsPresented) {
            Button("OK", role: .cancel) {
                importAlertMessage = nil
            }
        } message: {
            Text(importAlertMessage ?? "The selected file could not be imported.")
        }
        .fullScreenCover(item: $editingSong) { song in
            NavigationStack {
                SongEditView(song: song, isBackButtonActive: $isBackButtonActive) { updatedSong in
                    libraryStore.updateSong(updatedSong)
                }
            }
        }
        .fullScreenCover(item: $importedDraftSong) { song in
            NavigationStack {
                SongEditView(song: song, isBackButtonActive: $isBackButtonActive) { updatedSong in
                    libraryStore.addSongToLibrary(updatedSong)
                    importedDraftSong = nil
                }
            }
        }
    }

    private func selectableSongRow(_ song: Song) -> some View {
        let isSelected = selectedSongIDs.contains(song.id)

        return SongCardRow(
            song: song,
            isNowPlaying: song.id == currentPlayingSongID,
            onTap: {
                toggleSelection(for: song.id)
            },
            onMore: nil
        )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color("AppAccent") : Color.primary.opacity(0.10),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .overlay(alignment: .topLeading) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("AppAccent") : Color.primary.opacity(0.12))
                    Image(systemName: isSelected ? "checkmark" : "circle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.6))
                }
                .frame(width: 24, height: 24)
                .padding(8)
            }
    }

    private var addMenuOverlay: some View {
        ZStack {
            Rectangle()
                .fill(Color("opposite").opacity(0.18))
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .onTapGesture {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isAddMenuPresented = false
                    }
                }

            VStack(spacing: 0) {
                addMenuRow(title: "Upload from Device", systemImage: "tray.and.arrow.down") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isAddMenuPresented = false
                    }
                    isDeviceImporterPresented = true
                }
                Divider().opacity(0.6)
                addMenuRow(title: "Upload from YouTube", systemImage: "play.rectangle") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isAddMenuPresented = false
                    }
                    isYTUploadActive = true
                }
            }
            .padding(10)
            .frame(maxWidth: 240)
            .background(
                LinearGradient(
                    colors: [
                        Color("AppBackground"),
                        Color("opposite").opacity(0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 10)
            .padding(.trailing, AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing + 76)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }

    private func addMenuRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 22, alignment: .center)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))

                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.primary.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var importAlertIsPresented: Binding<Bool> {
        Binding(
            get: { importAlertMessage != nil },
            set: { newValue in
                if !newValue {
                    importAlertMessage = nil
                }
            }
        )
    }

    private func handleDeviceImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importAudioFile(at: url)
        case .failure:
            importAlertMessage = "The file picker could not open the selected file."
        }
    }

    private func importAudioFile(at url: URL) {
        let fileExtension = url.pathExtension.lowercased()
        guard ["mp3", "wav"].contains(fileExtension) else {
            importAlertMessage = "Only .mp3 and .wav files can be imported."
            return
        }

        let hasAccess = url.startAccessingSecurityScopedResource()
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
            importAlertMessage = "The selected file is not readable."
            return
        }

        Task {
            let draftSong = buildImportedSongDraft(from: url)
            await MainActor.run {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
                importedDraftSong = draftSong
            }
        }
    }

    private func buildImportedSongDraft(from url: URL) -> Song {
        return Song(
            id: UUID(),
            title: url.deletingPathExtension().lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines),
            artist: ""
        )
    }

    private func toggleSelection(for id: UUID) {
        if selectedSongIDs.contains(id) {
            selectedSongIDs.remove(id)
        } else {
            selectedSongIDs.insert(id)
        }
    }

    private func deleteSelectedSongs() {
        guard !selectedSongIDs.isEmpty else { return }
        for id in selectedSongIDs {
            libraryStore.delete(songID: id)
        }
        selectedSongIDs.removeAll()
        isSelecting = false
    }
}

// MARK: - Empty States

private struct SongLibraryEmptyState: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "music.note")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color.primary.opacity(0.20))

            Text("No Songs Yet")
                .font(.system(size: 18, weight: .semibold))

            Text("Tap + to import an MP3 or WAV,\nor convert a track from YouTube.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

private struct SongLibraryNoResults: View {
    let query: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color.primary.opacity(0.20))

            Text("No Results")
                .font(.system(size: 17, weight: .semibold))

            Text("Nothing matches \"\(query)\".")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
}

#Preview("Songs") {
    SongLibraryPreviewWrapper()
}

private struct SongLibraryPreviewWrapper: View {
    @State private var isSidebarOpen: Bool = false
    @State private var isBackButtonActive: Bool = false
    @Namespace private var chromeNS

    var body: some View {
        SongLibraryView(
            isSidebarOpen: $isSidebarOpen,
            isBackButtonActive: $isBackButtonActive,
            chromeNS: chromeNS,
            currentTab: .songs,
            currentPlayingSongID: nil,
            onPlaySong: { _ in }
        )
        .environmentObject(LibraryStore())
    }
}
