import SwiftUI

final class LibraryStore: ObservableObject {
    @Published var librarySongs: [Song]
    @Published var playlists: [Playlist]
    @Published var queue: [Song] = []

    // Playlist -> ordered song ids
    @Published private(set) var playlistSongIDs: [UUID: [UUID]] = [:]
    // Optional per-playlist artwork stored as serializable image data
    @Published private(set) var playlistArtwork: [UUID: ArtworkAsset] = [:]

    init() {
        self.librarySongs = MockData.songs
        self.playlists = MockData.playlists
        self.playlistSongIDs = MockData.seededPlaylistSongIDs(songs: librarySongs, playlists: playlists)
        syncAllPlaylistCounts()
    }

    func duplicate(song: Song) {
        let copy = Song(
            id: UUID(),
            title: "\(song.title) Copy",
            artist: song.artist,
            artwork: song.artwork,
            settings: song.settings
        )
        librarySongs.append(copy)
    }

    func importSong(fromFileURL fileURL: URL) {
        let name = fileURL.deletingPathExtension().lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = name.components(separatedBy: " - ")

        let title: String
        let artist: String

        if components.count >= 2 {
            artist = components.dropLast().joined(separator: " - ")
            title = components.last ?? name
        } else {
            title = name.isEmpty ? "Imported Track" : name
            artist = "Unknown Artist"
        }

        let importedSong = Song(id: UUID(), title: title, artist: artist)
        librarySongs.insert(importedSong, at: 0)
    }

    func delete(songID: UUID) {
        librarySongs.removeAll { $0.id == songID }
        queue.removeAll { $0.id == songID }
        for key in playlistSongIDs.keys {
            playlistSongIDs[key]?.removeAll { $0 == songID }
        }
        syncAllPlaylistCounts()
    }

    func addToQueue(song: Song) {
        queue.append(song)
    }

    func popQueue() -> Song? {
        guard !queue.isEmpty else { return nil }
        return queue.removeFirst()
    }

    func addSong(_ song: Song, to playlistID: UUID) {
        guard playlists.contains(where: { $0.id == playlistID }) else { return }
        var ids = playlistSongIDs[playlistID] ?? []
        ids.append(song.id)
        playlistSongIDs[playlistID] = ids
        syncPlaylistCount(for: playlistID)
    }

    func removeSong(songID: UUID, from playlistID: UUID) {
        guard playlists.contains(where: { $0.id == playlistID }) else { return }
        guard var ids = playlistSongIDs[playlistID] else { return }
        ids.removeAll { $0 == songID }
        playlistSongIDs[playlistID] = ids
        syncPlaylistCount(for: playlistID)
    }

    @discardableResult
    func createPlaylist(name: String, artwork: ArtworkAsset? = nil) -> Playlist {
        let playlist = Playlist(id: UUID(), name: name, count: 0)
        playlists.append(playlist)
        playlistSongIDs[playlist.id] = []
        if let artwork {
            playlistArtwork[playlist.id] = artwork
        }
        return playlist
    }

    func deletePlaylists(ids: Set<UUID>) {
        playlists.removeAll { ids.contains($0.id) }
        for id in ids {
            playlistSongIDs.removeValue(forKey: id)
            playlistArtwork.removeValue(forKey: id)
        }
    }

    func updateSong(_ updated: Song) {
        guard let index = librarySongs.firstIndex(where: { $0.id == updated.id }) else { return }
        librarySongs[index] = updated
        for queueIndex in queue.indices where queue[queueIndex].id == updated.id {
            queue[queueIndex] = updated
        }
    }

    func setPlaylistArtwork(_ artwork: ArtworkAsset?, for playlistID: UUID) {
        guard playlists.contains(where: { $0.id == playlistID }) else { return }
        if let artwork {
            playlistArtwork[playlistID] = artwork
        } else {
            playlistArtwork.removeValue(forKey: playlistID)
        }
    }

    func artwork(for playlistID: UUID) -> ArtworkAsset? {
        playlistArtwork[playlistID]
    }

    func songs(in playlistID: UUID) -> [Song] {
        guard let ids = playlistSongIDs[playlistID], !ids.isEmpty else { return [] }
        let map = Dictionary(uniqueKeysWithValues: librarySongs.map { ($0.id, $0) })
        return ids.compactMap { map[$0] }
    }

    private func syncAllPlaylistCounts() {
        playlists = playlists.map { playlist in
            Playlist(
                id: playlist.id,
                name: playlist.name,
                count: playlistSongIDs[playlist.id]?.count ?? 0
            )
        }
    }

    private func syncPlaylistCount(for playlistID: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        let playlist = playlists[index]
        playlists[index] = Playlist(
            id: playlist.id,
            name: playlist.name,
            count: playlistSongIDs[playlistID]?.count ?? 0
        )
    }
}
