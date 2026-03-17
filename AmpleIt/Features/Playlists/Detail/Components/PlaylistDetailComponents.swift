import SwiftUI

struct PlaylistActionButton: View {
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

struct PlaylistTrackRow: View {
    let song: Song
    let isNowPlaying: Bool
    let onTap: () -> Void
    let onAddToQueue: () -> Void
    let onRemoveFromPlaylist: () -> Void
    var isSelecting: Bool = false
    var isSelected: Bool = false
    var onSelectToggle: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            Button(action: isSelecting ? { onSelectToggle?() } : onTap) {
                HStack(spacing: 14) {
                    SongArtworkView(song: song)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            if isNowPlaying {
                                NowPlayingIndicator(size: 14)
                            }

                            Text(song.title)
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }

                        Text(song.artist)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isSelecting {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color("AppAccent") : Color.primary.opacity(0.12))
                    Image(systemName: isSelected ? "checkmark" : "circle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.6))
                }
                .frame(width: 24, height: 24)
            } else {
                Menu {
                    Button("Add to Queue", systemImage: "text.line.first.and.arrowtriangle.forward") {
                        onAddToQueue()
                    }
                    Button("Remove from Playlist", systemImage: "minus.circle", role: .destructive) {
                        onRemoveFromPlaylist()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Song actions")
            }
        }
        .padding(.vertical, 12)
    }
}

struct AddSongsToPlaylistSheet: View {
    let songs: [Song]
    let onAdd: (Set<UUID>) -> Void
    let onCancel: () -> Void

    @State private var searchText: String = ""
    @State private var selectedSongIDs: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss

    private var filteredSongs: [Song] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return songs }
        return songs.filter {
            $0.title.lowercased().contains(query) || $0.artist.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredSongs.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Songs Available" : "No Matching Songs",
                        systemImage: searchText.isEmpty ? "music.note.list" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? "All songs in your library are already in this playlist." : "Try a different title or artist.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredSongs) { song in
                        Button {
                            toggleSelection(for: song.id)
                        } label: {
                            HStack(spacing: 12) {
                                SongArtworkView(song: song)
                                    .frame(width: 52, height: 52)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(song.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(song.artist)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                ZStack {
                                    Circle()
                                        .fill(selectedSongIDs.contains(song.id) ? Color("AppAccent") : Color.primary.opacity(0.12))
                                    Image(systemName: selectedSongIDs.contains(song.id) ? "checkmark" : "circle")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(selectedSongIDs.contains(song.id) ? Color("AppBackground") : Color.primary.opacity(0.6))
                                }
                                .frame(width: 24, height: 24)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Add Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add (\(selectedSongIDs.count))") {
                        onAdd(selectedSongIDs)
                        dismiss()
                    }
                    .disabled(selectedSongIDs.isEmpty)
                }
            }
        }
        .presentationBackground(Color("AppBackground"))
    }

    private func toggleSelection(for id: UUID) {
        if selectedSongIDs.contains(id) {
            selectedSongIDs.remove(id)
        } else {
            selectedSongIDs.insert(id)
        }
    }
}

#Preview("Playlist Action Button") {
    VStack(spacing: 12) {
        PlaylistActionButton(title: "Play", systemImage: "play.fill") {}
        PlaylistActionButton(title: "Shuffle", systemImage: "shuffle") {}
    }
    .padding()
    .background(Color("AppBackground"))
}

#Preview("Playlist Track Row") {
    VStack(spacing: 0) {
        PlaylistTrackRow(
            song: MockData.songs[0],
            isNowPlaying: true,
            onTap: {},
            onAddToQueue: {},
            onRemoveFromPlaylist: {}
        )
        PlaylistTrackRow(
            song: MockData.songs[1],
            isNowPlaying: false,
            onTap: {},
            onAddToQueue: {},
            onRemoveFromPlaylist: {}
        )
    }
    .background(Color("AppBackground"))
}

#Preview("Add Songs To Playlist Sheet") {
    AddSongsToPlaylistSheet(
        songs: MockData.songs,
        onAdd: { _ in },
        onCancel: {}
    )
}
