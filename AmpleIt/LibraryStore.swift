import SwiftUI

final class LibraryStore: ObservableObject {
    @Published var librarySongs: [Song]
    @Published var playlists: [Playlist]
    @Published var queue: [Song] = []

    // Playlist -> ordered song ids
    @Published private(set) var playlistSongIDs: [UUID: [UUID]] = [:]
    // Optional per-playlist artwork for user-created playlists
    @Published private(set) var playlistArtwork: [UUID: Image] = [:]

    init() {
        self.librarySongs = MockData.songs
        self.playlists = MockData.playlists
        for playlist in playlists {
            playlistSongIDs[playlist.id] = []
        }
    }

    func duplicate(song: Song) {
        let copy = Song(id: UUID(), title: "\(song.title) Copy", artist: song.artist)
        librarySongs.append(copy)
    }

    func delete(songID: UUID) {
        librarySongs.removeAll { $0.id == songID }
        queue.removeAll { $0.id == songID }
        for key in playlistSongIDs.keys {
            playlistSongIDs[key]?.removeAll { $0 == songID }
        }
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

        if let index = playlists.firstIndex(where: { $0.id == playlistID }) {
            let playlist = playlists[index]
            playlists[index] = Playlist(id: playlist.id, name: playlist.name, count: playlist.count + 1)
        }
    }

    @discardableResult
    func createPlaylist(name: String, artwork: Image? = nil) -> Playlist {
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

    func songs(in playlistID: UUID) -> [Song] {
        guard let ids = playlistSongIDs[playlistID], !ids.isEmpty else { return [] }
        let map = Dictionary(uniqueKeysWithValues: librarySongs.map { ($0.id, $0) })
        return ids.compactMap { map[$0] }
    }
}
