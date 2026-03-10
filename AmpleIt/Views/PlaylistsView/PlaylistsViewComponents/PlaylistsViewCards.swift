import SwiftUI

struct PlaylistCard: View {
    let playlist: Playlist
    let artwork: Image?
    let artworkSide: CGFloat
    private let cornerRadius: CGFloat = 22

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(0.06))

                if let artwork {
                    artwork
                        .resizable()
                        .scaledToFill()
                        .frame(width: artworkSide, height: artworkSide)
                        .clipped()
                } else {
                    ArtworkPlaceholder(seed: playlist.id.uuidString)
                }
            }
            .frame(width: artworkSide, height: artworkSide)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            Text(playlist.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text("\(playlist.count) songs")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }
}

struct PlaylistCardSelectable: View {
    let playlist: Playlist
    let artwork: Image?
    let isSelected: Bool
    let artworkSide: CGFloat

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PlaylistCard(playlist: playlist, artwork: artwork, artworkSide: artworkSide)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(isSelected ? Color("AppAccent") : Color.primary.opacity(0.12), lineWidth: 2)
                )

            ZStack {
                Circle()
                    .fill(isSelected ? Color("AppAccent") : Color.primary.opacity(0.12))
                Image(systemName: isSelected ? "checkmark" : "circle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isSelected ? Color("AppBackground") : Color.primary.opacity(0.6))
            }
            .frame(width: 24, height: 24)
            .padding(8)
        }
    }
}

struct PlaylistItem: Identifiable {
    let playlist: Playlist
    let artwork: Image?

    var id: UUID { playlist.id }
}
