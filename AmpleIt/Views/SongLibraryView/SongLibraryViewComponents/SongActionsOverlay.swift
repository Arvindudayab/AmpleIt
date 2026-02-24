import SwiftUI

struct SongActionsOverlay: View {
    let song: Song
    @Binding var isPresented: Bool
    @Binding var isBackButtonActive: Bool
    @EnvironmentObject private var libraryStore: LibraryStore

    var onEdit: (() -> Void)? = nil
    var onDuplicate: (() -> Void)? = nil
    var onAddToQueue: (() -> Void)? = nil
    var onAddToPlaylist: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    private enum Route: Hashable {
        case edit
    }

    @State private var path = NavigationPath()
    @State private var isPlaylistPickerCardPresented: Bool = false
    @State private var isCreatePlaylistPresented: Bool = false
    @State private var isDeleteConfirmationPresented: Bool = false
    @State private var newPlaylistName: String = ""
    @State private var newPlaylistArtwork: Image? = nil
    @State private var showArtworkOverlay: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Rectangle()
                    .fill(Color("opposite").opacity(0.22))
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                            isPresented = false
                        }
                    }

                if isPlaylistPickerCardPresented {
                    playlistPickerCard
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    actionsCard
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .edit:
                    SongEditView(isBackButtonActive: $isBackButtonActive)
                }
            }
            .sheet(isPresented: $isCreatePlaylistPresented) {
                CreatePlaylistFormSheet(
                    name: $newPlaylistName,
                    artwork: $newPlaylistArtwork,
                    showArtworkOverlay: $showArtworkOverlay,
                    onCreate: {
                        let trimmed = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let created = libraryStore.createPlaylist(name: trimmed, artwork: newPlaylistArtwork)
                        libraryStore.addSong(song, to: created.id)
                        onAddToPlaylist?()
                        newPlaylistName = ""
                        newPlaylistArtwork = nil
                        showArtworkOverlay = false
                        isCreatePlaylistPresented = false
                        isPlaylistPickerCardPresented = false
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                            isPresented = false
                        }
                    },
                    onDone: {
                        isCreatePlaylistPresented = false
                        showArtworkOverlay = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color("AppBackground"))
            }
            .confirmationDialog(
                "Delete this song?",
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isPresented = false
                    }
                    onDelete?()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the song from your library and playlists.")
            }
        }
        .allowsHitTesting(isPresented)
    }

    private var actionsCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ArtworkPlaceholder(seed: song.id.uuidString)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
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
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider().opacity(0.6)

            VStack(spacing: 0) {
                actionRow(title: "Edit", systemImage: "pencil") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isPresented = false
                    }
                    path.append(Route.edit)
                    onEdit?()
                }
                Divider().opacity(0.6)
                actionRow(title: "Duplicate", systemImage: "square.fill.on.square.fill") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isPresented = false
                    }
                    onDuplicate?()
                }
                Divider().opacity(0.6)
                actionRow(title: "Add to Queue", systemImage: "text.line.first.and.arrowtriangle.forward") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isPresented = false
                    }
                    onAddToQueue?()
                }
                Divider().opacity(0.6)
                actionRow(title: "Add to Playlist", systemImage: "text.badge.plus") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isPlaylistPickerCardPresented = true
                    }
                }
                Divider().opacity(0.6)
                actionRow(title: "Delete", systemImage: "trash", isDestructive: true) {
                    isDeleteConfirmationPresented = true
                }
            }
            .padding(.bottom, 10)
        }
        .frame(maxWidth: 360)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.primary.opacity(0.10), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var playlistPickerCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add to Playlist")
                    .font(.headline.weight(.semibold))
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isPlaylistPickerCardPresented = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider().opacity(0.6)

            VStack(spacing: 0) {
                actionRow(title: "New Playlist", systemImage: "plus.circle.fill") {
                    isCreatePlaylistPresented = true
                }
                if !libraryStore.playlists.isEmpty {
                    Divider().opacity(0.6)
                }
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(libraryStore.playlists) { playlist in
                            Button {
                                libraryStore.addSong(song, to: playlist.id)
                                onAddToPlaylist?()
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                                    isPresented = false
                                    isPlaylistPickerCardPresented = false
                                }
                            } label: {
                                HStack {
                                    Text(playlist.name)
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    Text("\(playlist.count)")
                                        .foregroundStyle(.secondary)
                                }
                                .foregroundStyle(Color.primary.opacity(0.92))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if playlist.id != libraryStore.playlists.last?.id {
                                Divider().opacity(0.6)
                            }
                        }
                    }
                }
                .frame(maxHeight: 240)
            }
            .padding(.bottom, 10)
        }
        .frame(maxWidth: 360)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.primary.opacity(0.10), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var cardBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppBackground"),
                Color("opposite").opacity(0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func actionRow(title: String, systemImage: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 24, alignment: .center)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))

                Spacer()
            }
            .foregroundStyle(isDestructive ? Color.red : Color.primary.opacity(0.92))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
