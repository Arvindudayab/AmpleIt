import SwiftUI

struct PlaylistActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(0.04),
                                Color("AppAccent").opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct PlaylistTrackRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 14) {
            ArtworkPlaceholder(seed: song.id.uuidString)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 12)
    }
}
