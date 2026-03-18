import SwiftUI

final class LibraryStore: ObservableObject {

    // MARK: - Published state

    @Published var librarySongs: [Song] = []
    @Published var playlists: [Playlist] = []
    @Published var queue: [Song] = []
    @Published private(set) var recentlyPlayedIDs: [UUID] = []
    @Published var userPresets: [SongPreset] = []
    @Published private(set) var playlistSongIDs: [UUID: [UUID]] = [:]
    @Published private(set) var playlistArtwork: [UUID: ArtworkAsset] = [:]

    var allPresets: [SongPreset] { SongPreset.builtIn + userPresets }

    // MARK: - Persistence

    /// Serial queue so concurrent saves never interleave writes.
    private let saveQueue = DispatchQueue(label: "com.ampleit.persistence", qos: .utility)

    // MARK: - Init

    init() {
        loadFromDisk()
    }

    // MARK: - Library mutations

    func addSongToLibrary(_ song: Song, atBeginning: Bool = true) {
        if atBeginning { librarySongs.insert(song, at: 0) } else { librarySongs.append(song) }
        if let artwork = song.artwork {
            PersistenceStore.saveArtwork(artwork, key: songArtworkKey(song.id))
        }
        scheduleSave()
    }

    func duplicate(song: Song) {
        let copy = Song(
            id: UUID(),
            title: "\(song.title) Copy",
            artist: song.artist,
            artwork: song.artwork,
            settings: song.settings,
            fileURL: song.fileURL
        )
        librarySongs.append(copy)
        if let artwork = copy.artwork {
            PersistenceStore.saveArtwork(artwork, key: songArtworkKey(copy.id))
        }
        scheduleSave()
    }

    func delete(songID: UUID) {
        librarySongs.removeAll { $0.id == songID }
        queue.removeAll { $0.id == songID }
        for key in playlistSongIDs.keys {
            playlistSongIDs[key]?.removeAll { $0 == songID }
        }
        syncAllPlaylistCounts()
        PersistenceStore.deleteArtwork(key: songArtworkKey(songID))
        scheduleSave()
    }

    func updateSong(_ updated: Song) {
        guard let index = librarySongs.firstIndex(where: { $0.id == updated.id }) else { return }
        let old = librarySongs[index]
        librarySongs[index] = updated
        for i in queue.indices where queue[i].id == updated.id { queue[i] = updated }

        if updated.artwork != old.artwork {
            if let artwork = updated.artwork {
                PersistenceStore.saveArtwork(artwork, key: songArtworkKey(updated.id))
            } else {
                PersistenceStore.deleteArtwork(key: songArtworkKey(updated.id))
            }
        }
        scheduleSave()
    }

    func recordPlay(songID: UUID) {
        recentlyPlayedIDs.removeAll { $0 == songID }
        recentlyPlayedIDs.insert(songID, at: 0)
        if recentlyPlayedIDs.count > 5 {
            recentlyPlayedIDs = Array(recentlyPlayedIDs.prefix(5))
        }
        scheduleSave()
    }

    // MARK: - Queue (ephemeral — not persisted)

    func addToQueue(song: Song) { queue.append(song) }

    func popQueue() -> Song? {
        guard !queue.isEmpty else { return nil }
        return queue.removeFirst()
    }

    func replaceQueue(with songs: [Song]) { queue = songs }

    // MARK: - Playlist mutations

    @discardableResult
    func createPlaylist(name: String, artwork: ArtworkAsset? = nil) -> Playlist {
        let playlist = Playlist(id: UUID(), name: name, count: 0)
        playlists.append(playlist)
        playlistSongIDs[playlist.id] = []
        if let artwork {
            playlistArtwork[playlist.id] = artwork
            PersistenceStore.saveArtwork(artwork, key: playlistArtworkKey(playlist.id))
        }
        scheduleSave()
        return playlist
    }

    func deletePlaylists(ids: Set<UUID>) {
        playlists.removeAll { ids.contains($0.id) }
        for id in ids {
            playlistSongIDs.removeValue(forKey: id)
            playlistArtwork.removeValue(forKey: id)
            PersistenceStore.deleteArtwork(key: playlistArtworkKey(id))
        }
        scheduleSave()
    }

    func renamePlaylist(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = playlists.firstIndex(where: { $0.id == id }) else { return }
        let old = playlists[index]
        playlists[index] = Playlist(id: old.id, name: trimmed, count: old.count)
        scheduleSave()
    }

    func addSong(_ song: Song, to playlistID: UUID) {
        guard playlists.contains(where: { $0.id == playlistID }) else { return }
        var ids = playlistSongIDs[playlistID] ?? []
        ids.append(song.id)
        playlistSongIDs[playlistID] = ids
        syncPlaylistCount(for: playlistID)
        scheduleSave()
    }

    func removeSong(songID: UUID, from playlistID: UUID) {
        guard playlists.contains(where: { $0.id == playlistID }) else { return }
        guard var ids = playlistSongIDs[playlistID] else { return }
        ids.removeAll { $0 == songID }
        playlistSongIDs[playlistID] = ids
        syncPlaylistCount(for: playlistID)
        scheduleSave()
    }

    func setPlaylistArtwork(_ artwork: ArtworkAsset?, for playlistID: UUID) {
        guard playlists.contains(where: { $0.id == playlistID }) else { return }
        if let artwork {
            playlistArtwork[playlistID] = artwork
            PersistenceStore.saveArtwork(artwork, key: playlistArtworkKey(playlistID))
        } else {
            playlistArtwork.removeValue(forKey: playlistID)
            PersistenceStore.deleteArtwork(key: playlistArtworkKey(playlistID))
        }
        scheduleSave()
    }

    func addUserPreset(_ preset: SongPreset) {
        userPresets.append(preset)
        scheduleSave()
    }

    func updateUserPreset(_ updated: SongPreset) {
        guard let index = userPresets.firstIndex(where: { $0.id == updated.id }) else { return }
        userPresets[index] = updated
        scheduleSave()
    }

    func deleteUserPreset(id: UUID) {
        userPresets.removeAll { $0.id == id }
        scheduleSave()
    }

    // MARK: - Computed

    var recentlyAddedSongs: [Song] {
        Array(librarySongs.sorted { $0.dateAdded > $1.dateAdded }.prefix(5))
    }

    var recentlyPlayedSongs: [Song] {
        let map = Dictionary(uniqueKeysWithValues: librarySongs.map { ($0.id, $0) })
        return recentlyPlayedIDs.compactMap { map[$0] }
    }

    func artwork(for playlistID: UUID) -> ArtworkAsset? { playlistArtwork[playlistID] }

    func songs(in playlistID: UUID) -> [Song] {
        guard let ids = playlistSongIDs[playlistID], !ids.isEmpty else { return [] }
        let map = Dictionary(uniqueKeysWithValues: librarySongs.map { ($0.id, $0) })
        return ids.compactMap { map[$0] }
    }

    // MARK: - Private – playlist count sync

    fileprivate func syncAllPlaylistCounts() {
        playlists = playlists.map { p in
            Playlist(id: p.id, name: p.name, count: playlistSongIDs[p.id]?.count ?? 0)
        }
    }

    private func syncPlaylistCount(for playlistID: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        let p = playlists[index]
        playlists[index] = Playlist(id: p.id, name: p.name, count: playlistSongIDs[playlistID]?.count ?? 0)
    }

    // MARK: - Private – persistence

    private func loadFromDisk() {
        guard let snapshot = PersistenceStore.loadLibrary() else { return }

        librarySongs = snapshot.songs.map { song in
            guard let artwork = PersistenceStore.loadArtwork(key: songArtworkKey(song.id)) else {
                return song
            }
            return Song(id: song.id, title: song.title, artist: song.artist,
                        artwork: artwork, settings: song.settings,
                        dateAdded: song.dateAdded, fileURL: song.fileURL)
        }

        playlists = snapshot.playlists

        playlistSongIDs = Dictionary(uniqueKeysWithValues:
            snapshot.playlistSongIDs.compactMap { key, value in
                guard let uuid = UUID(uuidString: key) else { return nil }
                return (uuid, value)
            }
        )

        for playlist in playlists {
            if let artwork = PersistenceStore.loadArtwork(key: playlistArtworkKey(playlist.id)) {
                playlistArtwork[playlist.id] = artwork
            }
        }

        userPresets = snapshot.userPresets
        recentlyPlayedIDs = snapshot.recentlyPlayedIDs
        syncAllPlaylistCounts()
    }

    private func makeSnapshot() -> LibrarySnapshot {
        LibrarySnapshot(
            songs: librarySongs,
            playlistSongIDs: Dictionary(uniqueKeysWithValues:
                playlistSongIDs.map { ($0.key.uuidString, $0.value) }
            ),
            playlists: playlists,
            userPresets: userPresets,
            recentlyPlayedIDs: recentlyPlayedIDs
        )
    }

    private func scheduleSave() {
        let snapshot = makeSnapshot()   // captured on main thread (safe)
        saveQueue.async {
            PersistenceStore.saveLibrary(snapshot)
        }
    }

    // MARK: - Private – artwork keys

    private func songArtworkKey(_ id: UUID) -> String     { "song_\(id.uuidString)" }
    private func playlistArtworkKey(_ id: UUID) -> String { "playlist_\(id.uuidString)" }
}

// MARK: - Debug / Preview

#if DEBUG
extension LibraryStore {
    static var preview: LibraryStore {
        let store = LibraryStore()
        store.librarySongs = MockData.songs
        store.playlists = MockData.playlists
        store.playlistSongIDs = MockData.seededPlaylistSongIDs(songs: store.librarySongs, playlists: store.playlists)
        store.syncAllPlaylistCounts()
        return store
    }
}
#endif
