import SwiftUI

struct SongCardRow: View {
    let song: Song

    var onEdit: (() -> Void)? = nil
    var onAddToPlaylist: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onMore: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            ArtworkPlaceholder(seed: song.id.uuidString)
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            VStack(alignment: .leading, spacing: 0) {
                Text(song.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                onMore?()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.06))
                    )
            }
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityLabel("More actions")
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.04),
                    Color.primary.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
