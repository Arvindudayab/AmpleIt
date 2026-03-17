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

#Preview("Song Artwork View") {
    SongArtworkView(song: MockData.songs.first!)
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding()
}
