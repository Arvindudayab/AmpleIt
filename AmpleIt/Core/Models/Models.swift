import SwiftUI
import UIKit

// Core audio-library value types used across the app.
struct SongPreset: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let speed: Double
    let pitch: Double
    let reverb: Double
    let bass: Double
    let mid: Double
    let treble: Double

    static let builtIn: [SongPreset] = [
        SongPreset(id: UUID(), name: "Default",        speed: 1.00, pitch:  0, reverb: 0.00, bass:  0, mid:  0, treble:  0),
        SongPreset(id: UUID(), name: "Warm",           speed: 1.00, pitch:  0, reverb: 0.10, bass:  3, mid:  0, treble: -2),
        SongPreset(id: UUID(), name: "Bass Boost",     speed: 1.00, pitch:  0, reverb: 0.00, bass:  8, mid:  1, treble:  0),
        SongPreset(id: UUID(), name: "Lo-Fi",          speed: 0.95, pitch:  0, reverb: 0.25, bass: -1, mid:  0, treble: -6),
        SongPreset(id: UUID(), name: "Vocal Clarity",  speed: 1.00, pitch:  0, reverb: 0.05, bass: -3, mid:  4, treble:  3),
    ]
}

struct SongSettings: Codable, Equatable {
    let preset: String
    let speed: Double
    let reverb: Double
    let bass: Double
    let mid: Double
    let treble: Double
    /// Pitch shift in semitones. Range −12…+12 (one octave each direction). 0 = unchanged.
    let pitch: Double

    static let `default` = SongSettings(
        preset: "Default",
        speed: 1.0,
        reverb: 0.0,
        bass: 0.0,
        mid: 0.0,
        treble: 0.0,
        pitch: 0.0
    )
}

struct Song: Identifiable, Equatable {
    let id: UUID
    let title: String
    let artist: String
    let artwork: ArtworkAsset?
    let settings: SongSettings
    let dateAdded: Date
    let fileURL: URL?

    init(
        id: UUID,
        title: String,
        artist: String,
        artwork: ArtworkAsset? = nil,
        settings: SongSettings = .default,
        dateAdded: Date = Date(),
        fileURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artwork = artwork
        self.settings = settings
        self.dateAdded = dateAdded
        self.fileURL = fileURL
    }
}

struct Playlist: Identifiable, Equatable, Codable {
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

    /// For loading pre-normalized artwork from disk — skips re-processing.
    init(imageData: Data) {
        self.imageData = imageData
    }

    var uiImage: UIImage? {
        UIImage(data: imageData)
    }

    var image: Image? {
        uiImage.map(Image.init(uiImage:))
    }
}

// MARK: - Codable

extension Song: Codable {
    // Artwork is excluded — stored as a separate .jpg file keyed by song ID.
    // fileURL is stored as just the filename (relative path) so it survives
    // app reinstalls that change the Documents directory prefix.
    enum CodingKeys: String, CodingKey {
        case id, title, artist, settings, dateAdded, audioFileName
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,        forKey: .id)
        try c.encode(title,     forKey: .title)
        try c.encode(artist,    forKey: .artist)
        try c.encode(settings,  forKey: .settings)
        try c.encode(dateAdded, forKey: .dateAdded)
        try c.encodeIfPresent(fileURL?.lastPathComponent, forKey: .audioFileName)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self,         forKey: .id)
        title     = try c.decode(String.self,       forKey: .title)
        artist    = try c.decode(String.self,       forKey: .artist)
        settings  = try c.decode(SongSettings.self, forKey: .settings)
        dateAdded = try c.decode(Date.self,         forKey: .dateAdded)
        artwork   = nil  // loaded separately by PersistenceStore

        if let fileName = try c.decodeIfPresent(String.self, forKey: .audioFileName) {
            let docs = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
            fileURL = docs
                .appendingPathComponent("AmpleItAudio")
                .appendingPathComponent(fileName)
        } else {
            fileURL = nil
        }
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
