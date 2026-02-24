//
//  Components.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.
//

import SwiftUI

// MARK: - Song row format
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

// MARK: - Sidebar-style actions overlay (replaces Menu)
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
            // Dim + blur backdrop
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
}

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct CreatePlaylistFormSheet: View {
    @Binding var name: String
    @Binding var artwork: Image?
    @Binding var showArtworkOverlay: Bool
    let onCreate: () -> Void
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showArtworkOverlay = true
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.primary.opacity(0.06))

                                Group {
                                    if let artwork {
                                        artwork
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        ArtworkPlaceholder(seed: "new-playlist")
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay {
                                    if showArtworkOverlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.black.opacity(0.25))
                                            .onTapGesture {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    showArtworkOverlay = false
                                                }
                                            }

                                        Button {
                                            if artwork == nil {
                                                artwork = Image(systemName: "photo")
                                            } else {
                                                artwork = nil
                                            }
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                showArtworkOverlay = false
                                            }
                                        } label: {
                                            Text("Replace")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Capsule().fill(Color.black.opacity(0.35)))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color("AppBackground"))
                } header: {
                    Text("Artwork")
                }

                Section {
                    TextField("Playlist name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(.primary.opacity(0.10), lineWidth: 1)
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color("AppBackground"))
                } header: {
                    Text("Name")
                }

                Section {
                    Button(action: onCreate) {
                        Text("Create")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color("AppAccent").opacity(0.25))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color("AppAccent").opacity(0.6), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .listRowBackground(Color("AppBackground"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle("Create Playlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                }
            }
        }
    }
}



// MARK: - Floating Add Button (primary -> gray gradient)
struct FloatingAddButton: View {
    var systemImage: String = "plus"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("AppBackground"),
                                Color.gray.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .overlay(Circle().strokeBorder(.white.opacity(0.22), lineWidth: 1))
                    .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.primary)
            }
        }
        .accessibilityLabel("Add")
    }
}

// MARK: - Artwork Placeholder (cover-style)
struct ArtworkPlaceholder: View {
    let seed: String

    var body: some View {
        ZStack {
            // Subtle cover-like gradient background
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.03),
                    Color("AppAccent").opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "music.note")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.28))
        }
        // Fill whatever size the parent gives us
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

// MARK: - Mock Models & Data
struct Song: Identifiable {
    let id: UUID
    let title: String
    let artist: String
}

struct Playlist: Identifiable {
    let id: UUID
    let name: String
    let count: Int
}

enum MockData {
    static let songs: [Song] = [
        .init(id: UUID(), title: "Midnight Drive", artist: "Nova"),
        .init(id: UUID(), title: "Golden Hour", artist: "Aria"),
        .init(id: UUID(), title: "Neon Skyline", artist: "Kairo"),
        .init(id: UUID(), title: "Afterglow", artist: "Selene"),
        .init(id: UUID(), title: "Slow Motion", artist: "The Satellites"),
        .init(id: UUID(), title: "Ocean Glass", artist: "Mira"),
        .init(id: UUID(), title: "Night Market", artist: "Juno"),
        .init(id: UUID(), title: "Paper Planes", artist: "Lumen"),
        .init(id: UUID(), title: "Static Bloom", artist: "Echo Park"),
        .init(id: UUID(), title: "Rainy Streetlights", artist: "Orchid")
    ]

    static let playlists: [Playlist] = [
        .init(id: UUID(), name: "Gym Mix", count: 18),
        .init(id: UUID(), name: "Late Night", count: 25),
        .init(id: UUID(), name: "Practice Loops", count: 12),
        .init(id: UUID(), name: "Road Trip", count: 34),
        .init(id: UUID(), name: "Chill", count: 20),
        .init(id: UUID(), name: "Focus", count: 16)
    ]
}
