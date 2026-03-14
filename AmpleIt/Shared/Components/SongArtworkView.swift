import SwiftUI

struct SongArtworkView: View {
    let song: Song

    var body: some View {
        ZStack {
            if let artworkImage = song.artwork?.image {
                artworkImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ArtworkPlaceholder(seed: song.id.uuidString)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}
