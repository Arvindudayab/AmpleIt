import SwiftUI
import UIKit

struct Song: Identifiable {
    let id: UUID
    let title: String
    let artist: String
}

struct Playlist: Identifiable {
    let id: UUID
    let name: String
    let count: Int
}

struct ArtworkAsset: Codable, Equatable {
    let imageData: Data

    init?(data: Data) {
        guard let uiImage = UIImage(data: data) else { return nil }
        self.imageData = uiImage.jpegData(compressionQuality: 0.9) ?? data
    }

    var uiImage: UIImage? {
        UIImage(data: imageData)
    }

    var image: Image? {
        uiImage.map(Image.init(uiImage:))
    }
}

enum MockData {
    static let songs: [Song] = [
        .init(id: UUID(), title: "Midnight Drive", artist: "Nova"),
        .init(id: UUID(), title: "Golden Hour", artist: "Aria"),
        .init(id: UUID(), title: "Neon Skyline", artist: "Kairo"),
        .init(id: UUID(), title: "Afterglow", artist: "Selene"),
        .init(id: UUID(), title: "Slow Motion", artist: "The Satellites"),
        .init(id: UUID(), title: "Ocean Glass", artist: "Mira"),
        .init(id: UUID(), title: "Night Market", artist: "Juno"),
        .init(id: UUID(), title: "Paper Planes", artist: "Lumen"),
        .init(id: UUID(), title: "Static Bloom", artist: "Echo Park"),
        .init(id: UUID(), title: "Rainy Streetlights", artist: "Orchid")
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
