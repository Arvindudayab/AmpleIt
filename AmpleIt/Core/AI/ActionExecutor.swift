import Foundation

struct ActionExecutor {
    let store: LibraryStore
    let currentNowPlayingID: UUID?
    let onPlaySong: ((Song) -> Void)?

    func execute(toolName: String, input: [String: Any]) -> String {
        switch toolName {
        case "build_queue":        return buildQueue(input: input)
        case "add_to_queue":       return addToQueue(input: input)
        case "edit_song_settings": return editSong(input: input)
        case "create_playlist":    return createPlaylist(input: input)
        default: return "Unknown tool: \(toolName)"
        }
    }

    // MARK: - build_queue

    private func buildQueue(input: [String: Any]) -> String {
        let ids   = input["song_ids"] as? [String] ?? []
        let songs = ids.compactMap { id in store.librarySongs.first { $0.id.uuidString == id } }
        guard !songs.isEmpty else { return "No matching songs found." }
        let first = songs[0]
        // If the first song is already playing, don't reload it — just update the upcoming queue.
        if first.id == currentNowPlayingID {
            store.replaceQueue(with: Array(songs.dropFirst()))
            return "Queue updated — continuing \"\(first.title)\" with \(songs.count - 1) song\(songs.count - 1 == 1 ? "" : "s") queued after."
        }
        store.replaceQueue(with: Array(songs.dropFirst()))
        onPlaySong?(first)
        return "Playing \"\(first.title)\" with \(songs.count - 1) song\(songs.count - 1 == 1 ? "" : "s") queued after."
    }

    // MARK: - add_to_queue

    private func addToQueue(input: [String: Any]) -> String {
        let ids   = input["song_ids"] as? [String] ?? []
        let songs = ids.compactMap { id in store.librarySongs.first { $0.id.uuidString == id } }
        guard !songs.isEmpty else { return "No matching songs found." }
        songs.forEach { store.addToQueue(song: $0) }
        return "Added \(songs.count) song\(songs.count == 1 ? "" : "s") to the queue."
    }

    // MARK: - edit_song_settings

    private func editSong(input: [String: Any]) -> String {
        guard let idStr = input["song_id"] as? String,
              let song = store.librarySongs.first(where: { $0.id.uuidString == idStr }) else {
            return "Song not found."
        }
        let old = song.settings
        let new = SongSettings(
            preset: old.preset,
            speed:  (input["speed"]  as? Double) ?? old.speed,
            reverb: (input["reverb"] as? Double) ?? old.reverb,
            bass:   (input["bass"]   as? Double) ?? old.bass,
            mid:    (input["mid"]    as? Double) ?? old.mid,
            treble: (input["treble"] as? Double) ?? old.treble,
            pitch:  (input["pitch"]  as? Double) ?? old.pitch
        )
        let updated = Song(id: song.id, title: song.title, artist: song.artist,
                           artwork: song.artwork, settings: new,
                           dateAdded: song.dateAdded, fileURL: song.fileURL)
        store.updateSong(updated)
        return "Updated settings for \"\(song.title)\"."
    }

    // MARK: - create_playlist

    private func createPlaylist(input: [String: Any]) -> String {
        let name  = (input["name"] as? String ?? "New Playlist")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let ids   = input["song_ids"] as? [String] ?? []
        let pl    = store.createPlaylist(name: name)
        let songs = ids.compactMap { id in store.librarySongs.first { $0.id.uuidString == id } }
        songs.forEach { store.addSong($0, to: pl.id) }
        return "Created playlist \"\(name)\" with \(songs.count) songs."
    }
}
