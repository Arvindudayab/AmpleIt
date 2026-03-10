import SwiftUI
import UIKit

struct SongSettings: Codable, Equatable {
    let preset: String
    let speed: Double
    let reverb: Double
    let bass: Double
    let mid: Double
    let treble: Double

    static let `default` = SongSettings(
        preset: "Default",
        speed: 1.0,
        reverb: 0.0,
        bass: 0.0,
        mid: 0.0,
        treble: 0.0
    )
}

struct Song: Identifiable, Equatable {
    let id: UUID
    let title: String
    let artist: String
    let artwork: ArtworkAsset?
    let settings: SongSettings

    init(
        id: UUID,
        title: String,
        artist: String,
        artwork: ArtworkAsset? = nil,
        settings: SongSettings = .default
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artwork = artwork
        self.settings = settings
    }
}

struct Playlist: Identifiable, Equatable {
    let id: UUID
    let name: String
    let count: Int
}

struct ArtworkAsset: Codable, Equatable {
    let imageData: Data

    init?(data: Data) {
        guard let uiImage = UIImage(data: data),
              let normalizedImage = uiImage.normalizedArtworkImage else { return nil }
        self.imageData = normalizedImage.jpegData(compressionQuality: 0.88) ?? data
    }

    var uiImage: UIImage? {
        UIImage(data: imageData)
    }

    var image: Image? {
        uiImage.map(Image.init(uiImage:))
    }
}

private extension UIImage {
    var normalizedArtworkImage: UIImage? {
        let maxDimension: CGFloat = 1600
        let longestSide = max(size.width, size.height)
        let scaleRatio = longestSide > maxDimension ? (maxDimension / longestSide) : 1
        let targetSize = CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
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
