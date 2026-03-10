import SwiftUI

struct SongArtworkView: View {
    let song: Song

    var body: some View {
        Group {
            if let artworkImage = song.artwork?.image {
                artworkImage
                    .resizable()
                    .scaledToFill()
            } else {
                ArtworkPlaceholder(seed: song.id.uuidString)
            }
        }
        .clipped()
    }
}
