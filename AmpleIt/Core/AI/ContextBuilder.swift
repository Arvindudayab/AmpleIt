import Foundation

struct ContextBuilder {

    static func build(store: LibraryStore, currentNowPlayingID: UUID? = nil) -> String {
        var parts: [String] = []

        // NOW PLAYING — always present so Amp knows the playback state
        if let id = currentNowPlayingID,
           let song = store.librarySongs.first(where: { $0.id == id }) {
            let s = song.settings
            var sp: [String] = []
            if s.speed  != 1.0 { sp.append("speed:\(s.speed)x") }
            if s.pitch  != 0   { sp.append("pitch:\(s.pitch)st") }
            if s.reverb  > 0   { sp.append("reverb:\(String(format: "%.2f", s.reverb))") }
            if s.bass   != 0   { sp.append("bass:\(s.bass)dB") }
            if s.mid    != 0   { sp.append("mid:\(s.mid)dB") }
            if s.treble != 0   { sp.append("treble:\(s.treble)dB") }
            let settingsStr = sp.isEmpty ? "all default" : sp.joined(separator: " ")
            parts.append("NOW PLAYING: \"\(song.title)\" — \(song.artist) [id:\(song.id)]\nCurrent settings: \(settingsStr)")
        } else {
            parts.append("NOW PLAYING: nothing")
        }

        // QUEUE — shown with IDs so Amp can reason about what's already queued
        if !store.queue.isEmpty {
            let shown = store.queue.prefix(20)
            let list  = shown.map { "• \($0.title) — \($0.artist) [id:\($0.id)]" }.joined(separator: "\n")
            let tail  = store.queue.count > 20 ? "\n…and \(store.queue.count - 20) more" : ""
            parts.append("QUEUE (\(store.queue.count) songs):\n\(list)\(tail)")
        } else {
            parts.append("QUEUE: empty")
        }

        // LIBRARY
        if !store.librarySongs.isEmpty {
            let songs = store.librarySongs.prefix(60)
            let unanalyzed = songs.filter { store.songAnalysis[$0.id] == nil }.count
            let lines = songs.map { song -> String in
                let a   = store.songAnalysis[song.id]
                let bpm = a.map { String(format: "%.0f", $0.bpm) } ?? "?"
                let key = a?.key ?? "?"
                let nrg = a.map { String(format: "%.2f", $0.energy) } ?? "?"
                let s = song.settings
                var sp: [String] = []
                if s.speed  != 1.0 { sp.append("speed:\(s.speed)x") }
                if s.pitch  != 0   { sp.append("pitch:\(s.pitch)st") }
                if s.reverb  > 0   { sp.append("reverb:\(String(format: "%.2f", s.reverb))") }
                if s.bass   != 0   { sp.append("bass:\(s.bass)dB") }
                if s.mid    != 0   { sp.append("mid:\(s.mid)dB") }
                if s.treble != 0   { sp.append("treble:\(s.treble)dB") }
                let settingsSuffix = sp.isEmpty ? "" : " {\(sp.joined(separator: ","))}"
                return "• \(song.title) — \(song.artist) [id:\(song.id)|bpm:\(bpm)|key:\(key)|energy:\(nrg)]\(settingsSuffix)"
            }
            var header = "LIBRARY (\(store.librarySongs.count) songs"
            if store.librarySongs.count > 60 { header += ", showing first 60" }
            header += ")"
            if unanalyzed > 0 {
                header += " — NOTE: \(unanalyzed) song\(unanalyzed == 1 ? "" : "s") still being analyzed (?). Infer mood from title/artist where possible."
            }
            parts.append("\(header):\n" + lines.joined(separator: "\n"))
        }

        // PLAYLISTS
        if !store.playlists.isEmpty {
            let list = store.playlists.map {
                "• \($0.name) (\($0.count) songs) [id:\($0.id)]"
            }.joined(separator: "\n")
            parts.append("PLAYLISTS:\n\(list)")
        }

        return parts.joined(separator: "\n\n")
    }
}
