import Foundation

// MARK: - Snapshot

/// A complete, serializable snapshot of the user's library.
/// Artwork is intentionally excluded — it is stored as individual .jpg files
/// in Documents/AmpleItArtwork/ so the JSON stays small.
struct LibrarySnapshot: Codable {
    var songs: [Song]
    var playlistSongIDs: [String: [UUID]]
    var playlists: [Playlist]
    var userPresets: [SongPreset]
    var recentlyPlayedIDs: [UUID]
    var songAnalysis: [String: AudioAnalysis]

    init(songs: [Song], playlistSongIDs: [String: [UUID]], playlists: [Playlist],
         userPresets: [SongPreset], recentlyPlayedIDs: [UUID],
         songAnalysis: [String: AudioAnalysis] = [:]) {
        self.songs             = songs
        self.playlistSongIDs   = playlistSongIDs
        self.playlists         = playlists
        self.userPresets       = userPresets
        self.recentlyPlayedIDs = recentlyPlayedIDs
        self.songAnalysis      = songAnalysis
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        songs             = try c.decode([Song].self,               forKey: .songs)
        playlistSongIDs   = try c.decode([String: [UUID]].self,     forKey: .playlistSongIDs)
        playlists         = try c.decode([Playlist].self,            forKey: .playlists)
        userPresets       = try c.decode([SongPreset].self,          forKey: .userPresets)
        recentlyPlayedIDs = try c.decode([UUID].self,               forKey: .recentlyPlayedIDs)
        songAnalysis      = (try? c.decodeIfPresent([String: AudioAnalysis].self,
                                                    forKey: .songAnalysis)) ?? [:]
    }
}

// MARK: - Store

/// Handles all disk I/O for the library: one JSON file for metadata,
/// individual JPEG files for artwork.
struct PersistenceStore {

    // MARK: - Paths

    private static let docsURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]

    private static var libraryFileURL: URL {
        docsURL.appendingPathComponent("library.json")
    }

    private static var artworkDirURL: URL {
        docsURL.appendingPathComponent("AmpleItArtwork", isDirectory: true)
    }

    // MARK: - Library JSON

    static func saveLibrary(_ snapshot: LibrarySnapshot) {
        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: libraryFileURL, options: .atomic)
        } catch {
            print("[Persistence] Save failed: \(error)")
        }
    }

    static func loadLibrary() -> LibrarySnapshot? {
        guard FileManager.default.fileExists(atPath: libraryFileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: libraryFileURL)
            return try decoder.decode(LibrarySnapshot.self, from: data)
        } catch {
            print("[Persistence] Load failed: \(error)")
            return nil
        }
    }

    // MARK: - Artwork files

    static func saveArtwork(_ asset: ArtworkAsset, key: String) {
        ensureArtworkDir()
        let url = artworkDirURL.appendingPathComponent("\(key).jpg")
        try? asset.imageData.write(to: url, options: .atomic)
    }

    static func loadArtwork(key: String) -> ArtworkAsset? {
        let url = artworkDirURL.appendingPathComponent("\(key).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return ArtworkAsset(imageData: data)
    }

    static func deleteArtwork(key: String) {
        let url = artworkDirURL.appendingPathComponent("\(key).jpg")
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Helpers

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private static func ensureArtworkDir() {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: artworkDirURL.path) else { return }
        try? fm.createDirectory(at: artworkDirURL, withIntermediateDirectories: true)
    }
}
