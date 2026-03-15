import SwiftUI
import UIKit

// Core audio-library value types used across the app.
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
    let dateAdded: Date

    init(
        id: UUID,
        title: String,
        artist: String,
        artwork: ArtworkAsset? = nil,
        settings: SongSettings = .default,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artwork = artwork
        self.settings = settings
        self.dateAdded = dateAdded
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
