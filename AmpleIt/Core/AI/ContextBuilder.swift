import Foundation

struct ContextBuilder {

    static func build(store: LibraryStore) -> String {
        var parts: [String] = []

        if !store.librarySongs.isEmpty {
            let songs = store.librarySongs.prefix(60)
            let unanalyzedCount = songs.filter { store.songAnalysis[$0.id] == nil }.count
            let lines = songs.map { song -> String in
                let a   = store.songAnalysis[song.id]
                let bpm = a.map { String(format: "%.0f", $0.bpm) } ?? "?"
                let key = a?.key ?? "?"
                let nrg = a.map { String(format: "%.2f", $0.energy) } ?? "?"
                return "• \(song.title) — \(song.artist) [id:\(song.id)|bpm:\(bpm)|key:\(key)|energy:\(nrg)]"
            }
            var header = "LIBRARY (\(store.librarySongs.count) songs)"
            if unanalyzedCount > 0 {
                header += " — NOTE: \(unanalyzedCount) song\(unanalyzedCount == 1 ? "" : "s") still being analyzed (bpm/key/energy shown as ?). Use title and artist to infer mood where possible."
            }
            parts.append("\(header):\n" + lines.joined(separator: "\n"))
        }

        if !store.queue.isEmpty {
            let list = store.queue.prefix(5).map { "• \($0.title)" }.joined(separator: "\n")
            parts.append("QUEUE (\(store.queue.count)):\n\(list)")
        }

        if !store.playlists.isEmpty {
            let list = store.playlists.map {
                "• \($0.name) (\($0.count) songs) [id:\($0.id)]"
            }.joined(separator: "\n")
            parts.append("PLAYLISTS:\n\(list)")
        }

        return parts.joined(separator: "\n\n")
    }
}
