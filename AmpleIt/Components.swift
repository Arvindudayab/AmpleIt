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
            }
            .buttonStyle(.plain)
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
    
    var onEdit: (() -> Void)? = nil
    var onDuplicate: (() -> Void)? = nil
    var onAddToPlaylist: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    private enum Route: Hashable {
        case edit
    }

    @State private var path = NavigationPath()

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

            // Floating panel
            VStack(spacing: 0) {
                // Header
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

                // Actions
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
                    actionRow(title: "Add to Playlist", systemImage: "text.badge.plus") {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                            isPresented = false
                        }
                        onAddToPlaylist?()
                    }
                    Divider().opacity(0.6)
                    actionRow(title: "Delete", systemImage: "trash", isDestructive: true) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                            isPresented = false
                        }
                        onDelete?()
                    }
                }
                .padding(.bottom, 10)
            }
            .frame(maxWidth: 360)
            .background(
                LinearGradient(
                    colors: [
                        Color("AppBackground"),
                        Color("opposite").opacity(0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(1),
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(.primary.opacity(0.10), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .edit:
                    SongEditView()
                }
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
