import SwiftUI

struct QueueCardView: View {
    let queueSongs: [Song]
    let onClose: () -> Void
    let onClearQueue: () -> Void
    var onTapSong: ((Song, Int) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Queue")
                    .font(.headline.weight(.semibold))
                Spacer()
                if !queueSongs.isEmpty {
                    Button("Clear") {
                        onClearQueue()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                    .padding(.trailing, 6)
                }
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
            .padding(14)

            Divider().opacity(0.6)

            if queueSongs.isEmpty {
                Text("No songs in queue.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(queueSongs.enumerated()), id: \.element.id) { index, song in
                            Button {
                                onTapSong?(song, index)
                            } label: {
                                HStack(spacing: 10) {
                                    SongArtworkView(song: song, placeholderSymbolSize: 12)
                                        .frame(width: 28, height: 28)
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(song.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .lineLimit(1)
                                        Text(song.artist)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if index < queueSongs.count - 1 {
                                Divider().opacity(0.5)
                            }
                        }
                    }
                }
                .frame(maxHeight: 240)
            }
        }
        .frame(maxWidth: 300)
        .background(
            LinearGradient(
                colors: [
                    Color("AppBackground"),
                    Color("opposite")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.primary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
    }
}

#Preview("Queue Card – With Songs") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()
        QueueCardView(
            queueSongs: Array(MockData.songs.prefix(4)),
            onClose: {},
            onClearQueue: {}
        )
        .padding()
    }
}

#Preview("Queue Card – Empty") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()
        QueueCardView(queueSongs: [], onClose: {}, onClearQueue: {})
            .padding()
    }
}
