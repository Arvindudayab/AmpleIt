import SwiftUI

struct SongPlayerView: View {
    let song: Song
    let queueSongs: [Song]
    @Binding var isPlaying: Bool
    let onClose: () -> Void
    let onNext: () -> Void
    let onPrev: () -> Void
    @State private var isQueueCardPresented: Bool = false

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            VStack(spacing: 22) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color.primary.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppLayout.horizontalPadding)

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.primary.opacity(0.06))

                    ArtworkPlaceholder(seed: song.id.uuidString)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, AppLayout.horizontalPadding)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(song.title)
                            .font(.system(size: 33, weight: .bold))
                            .lineLimit(1)
                        Text(song.artist)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
//                    Button {} label: {
//                        Image(systemName: "ellipsis")
//                            .font(.system(size: 18, weight: .semibold))
//                            .frame(width: 34, height: 34)
//                            .background(Color.primary.opacity(0.08), in: Circle())
//                    }
//                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppLayout.horizontalPadding)

                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.25))
                        .frame(height: 4)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.primary.opacity(0.75))
                                .frame(width: 140, height: 4)
                        }

                    HStack {
                        Text("4:40")
                        Spacer()
                        Text("-4:50")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, AppLayout.horizontalPadding)

                HStack(spacing: 48) {
                    Button(action: onPrev) {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 34, weight: .regular))
                            .frame(width: 56, height: 56)
                    }
                    .buttonStyle(.plain)

                    Button {
                        isPlaying.toggle()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 42, weight: .regular))
                            .frame(width: 72, height: 72)
                    }
                    .buttonStyle(.plain)

                    Button(action: onNext) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 34, weight: .regular))
                            .frame(width: 56, height: 56)
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.primary)

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            isQueueCardPresented.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Queue")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .background(Color("AppAccent").opacity(0.14), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color("AppAccent"), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.bottom, 18)
            }

            if isQueueCardPresented {
                Rectangle()
                    .fill(Color.black.opacity(0.16))
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            isQueueCardPresented = false
                        }
                    }

                QueueCardView(
                    queueSongs: queueSongs,
                    onClose: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            isQueueCardPresented = false
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, AppLayout.horizontalPadding)
                .padding(.bottom, 86)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

#Preview("Song Player") {
    SongPlayerView(
        song: MockData.songs.first!,
        queueSongs: MockData.songs,
        isPlaying: .constant(true),
        onClose: {},
        onNext: {},
        onPrev: {}
    )
}
