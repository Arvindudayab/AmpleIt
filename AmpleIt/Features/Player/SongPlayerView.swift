import SwiftUI

struct SongPlayerView: View {
    let songID: UUID
    let queueSongs: [Song]
    @Binding var isPlaying: Bool
    let onClose: () -> Void
    let onNext: () -> Void
    let onPrev: () -> Void
    @EnvironmentObject private var libraryStore: LibraryStore
    @State private var isQueueCardPresented: Bool = false

    private var song: Song? {
        libraryStore.librarySongs.first(where: { $0.id == songID })
    }

    private var artworkSide: CGFloat {
        UIScreen.main.bounds.width - (AppLayout.horizontalPadding * 2)
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            if let song {
                VStack(spacing: 22) {
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .background(Color.primary.opacity(0.08), in: Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, AppLayout.horizontalPadding)

                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.primary.opacity(0.06))

                        SongArtworkView(song: song)
                            .frame(width: artworkSide, height: artworkSide)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .frame(width: artworkSide, height: artworkSide)
                    .frame(maxWidth: .infinity)
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
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Queue")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 20)
                            .frame(height: 46)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.30),
                                                Color.white.opacity(0.06)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .black.opacity(0.14), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppLayout.horizontalPadding)
                    .padding(.bottom, 18)
                }
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
                    },
                    onClearQueue: {
                        libraryStore.replaceQueue(with: [])
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
        .simultaneousGesture(dismissGesture)
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .global)
            .onEnded { value in
                guard !isQueueCardPresented else { return }

                let isDownwardSwipe = value.translation.height > 90
                let isMostlyVertical = abs(value.translation.height) > abs(value.translation.width)
                guard isDownwardSwipe, isMostlyVertical else { return }
                onClose()
            }
    }
}

#Preview("Song Player") {
    SongPlayerView(
        songID: MockData.songs.first!.id,
        queueSongs: MockData.songs,
        isPlaying: .constant(true),
        onClose: {},
        onNext: {},
        onPrev: {}
    )
    .environmentObject(LibraryStore())
}
