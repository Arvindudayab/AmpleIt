import SwiftUI

struct PlaylistCard: View {
    let playlist: Playlist
    let artwork: Image?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.primary.opacity(0.06))

                if let artwork {
                    artwork
                        .resizable()
                        .scaledToFill()
                } else {
                    ArtworkPlaceholder(seed: playlist.id.uuidString)
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PlaylistCard(playlist: playlist, artwork: artwork)
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
