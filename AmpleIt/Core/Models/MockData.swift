import Foundation

enum MockData {
    private static let baseDate = Date()

    static let songs: [Song] = [
        .init(id: UUID(), title: "Midnight Drive",    artist: "Nova",          dateAdded: baseDate.addingTimeInterval(-3_600)),
        .init(id: UUID(), title: "Golden Hour",       artist: "Aria",          dateAdded: baseDate.addingTimeInterval(-7_200)),
        .init(id: UUID(), title: "Neon Skyline",      artist: "Kairo",         dateAdded: baseDate.addingTimeInterval(-86_400)),
        .init(id: UUID(), title: "Afterglow",         artist: "Selene",        dateAdded: baseDate.addingTimeInterval(-86_400 * 2)),
        .init(id: UUID(), title: "Slow Motion",       artist: "The Satellites",dateAdded: baseDate.addingTimeInterval(-86_400 * 3)),
        .init(id: UUID(), title: "Ocean Glass",       artist: "Mira",          dateAdded: baseDate.addingTimeInterval(-86_400 * 4)),
        .init(id: UUID(), title: "Night Market",      artist: "Juno",          dateAdded: baseDate.addingTimeInterval(-86_400 * 5)),
        .init(id: UUID(), title: "Paper Planes",      artist: "Lumen",         dateAdded: baseDate.addingTimeInterval(-86_400 * 6)),
        .init(id: UUID(), title: "Static Bloom",      artist: "Echo Park",     dateAdded: baseDate.addingTimeInterval(-86_400 * 7)),
        .init(id: UUID(), title: "Rainy Streetlights",artist: "Orchid",        dateAdded: baseDate.addingTimeInterval(-86_400 * 8)),
    ]

    static let playlists: [Playlist] = [
        .init(id: UUID(), name: "Gym Mix", count: 18),
        .init(id: UUID(), name: "Late Night", count: 25),
        .init(id: UUID(), name: "Practice Loops", count: 12),
        .init(id: UUID(), name: "Road Trip", count: 34),
        .init(id: UUID(), name: "Chill", count: 20),
        .init(id: UUID(), name: "Focus", count: 16)
    ]

    static func seededPlaylistSongIDs(
        songs: [Song] = songs,
        playlists: [Playlist] = playlists
    ) -> [UUID: [UUID]] {
        guard !songs.isEmpty else {
            return Dictionary(uniqueKeysWithValues: playlists.map { ($0.id, []) })
        }

        return Dictionary(uniqueKeysWithValues: playlists.enumerated().map { playlistOffset, playlist in
            let ids = (0..<playlist.count).map { index in
                songs[(index + playlistOffset) % songs.count].id
            }
            return (playlist.id, ids)
        })
    }
}
