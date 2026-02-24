//
//  PlaylistsDetailView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 1/9/26.
//

import SwiftUI
import PhotosUI
import UIKit

// This view is referenced by PlaylistsView.swift
struct PlaylistDetailView: View {
    let playlist: Playlist
    @Binding var isSidebarOpen: Bool
    let chromeNS: Namespace.ID
    @Binding var isBackButtonActive: Bool
    @EnvironmentObject private var libraryStore: LibraryStore
    
    @State private var artworkImage: Image? = nil
    @State private var showArtworkOverlay: Bool = false
    @State private var selectedArtworkItem: PhotosPickerItem? = nil
    @State private var isArtworkPickerPresented: Bool = false

    @State private var shuffledSongs: [Song]? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AppScreenContainer(
            title: "",
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS,
            wrapInNavigationStack: false,
            showsSidebarButton: false
        ) {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 18) {
                        // Cover (tap to reveal Replace prompt)
                        playlistCoverSection
                            .padding(.top, 18)

                        // Title (in-content).
                        Text(playlist.name)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding(.top, 4)

                        // Play / Shuffle buttons
                        HStack(spacing: 14) {
                            PlaylistActionButton(title: "Play", systemImage: "play.fill") {
                                print("Play \(playlist.name)")
                            }

                            PlaylistActionButton(title: "Shuffle", systemImage: "shuffle") {
                                print("Shuffle \(playlist.name)")
                                shuffledSongs = currentSongs.shuffled()
                            }
                        }
                        .padding(.horizontal, AppLayout.horizontalPadding)
                        .padding(.top, 2)

                        // Track list
                        VStack(spacing: 0) {
                            if currentSongs.isEmpty {
                                VStack(spacing: 8) {
                                    Text("No songs yet.")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Add songs to start building this playlist.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                            } else {
                                ForEach(currentSongs) { song in
                                    PlaylistTrackRow(song: song)
                                    Divider().opacity(0.5)
                                }
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal, AppLayout.horizontalPadding)

                        // Footer metadata
                        HStack {
                            Text("\(currentSongs.count) song\(currentSongs.count == 1 ? "" : "s"), \(estimatedMinutes) minutes")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, AppLayout.horizontalPadding)
                        .padding(.top, 6)
                        .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)
                    }
                }

                FloatingAddButton(systemImage: "plus") {
                    // Non-functional add button (placeholder)
                }
                .padding(.trailing, AppLayout.horizontalPadding)
                .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing)
            }
            
            .navigationBarBackButtonHidden(true)
            .simultaneousGesture(backSwipeGesture)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        handleBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                }
            }
            .tint(Color.primary)
            .onAppear {
                isBackButtonActive = true
            }
            .onDisappear {
                isBackButtonActive = false
                showArtworkOverlay = false
            }
            .photosPicker(
                isPresented: $isArtworkPickerPresented,
                selection: $selectedArtworkItem,
                matching: .images
            )
            .onChange(of: selectedArtworkItem) { _, item in
                Task {
                    guard let item,
                          let data = try? await item.loadTransferable(type: Data.self),
                          let uiImage = UIImage(data: data) else { return }
                    await MainActor.run {
                        artworkImage = Image(uiImage: uiImage)
                    }
                }
            }
            .onChange(of: libraryStore.songs(in: playlist.id).map(\.id)) { _, _ in
                shuffledSongs = nil
            }
        }
    }

    private var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                guard value.startLocation.x < 28 else { return }
                guard value.translation.width > 100 else { return }
                guard abs(value.translation.height) < 60 else { return }
                handleBack()
            }
    }

    private func handleBack() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            isBackButtonActive = false
        }
        dismiss()
    }
    
    private var playlistCoverSection: some View {
        Button {
            // First tap reveals the overlay (Replace prompt). Actual replacement happens when
            // the user taps the "Replace" button in the overlay.
            withAnimation(.easeInOut(duration: 0.15)) {
                showArtworkOverlay = true
            }
        } label: {
            ZStack {
                // Base artwork
                Group {
                    if let artworkImage {
                        artworkImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 320, height: 320)
                            .clipped()
                    } else {
                        ArtworkPlaceholder(seed: playlist.id.uuidString)
                    }
                }
                .frame(width: 320, height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                // Overlay shown only after tap
                if showArtworkOverlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.28))
                        .frame(width: 320, height: 320)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showArtworkOverlay = false
                            }
                        }

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showArtworkOverlay = false
                        }
                        isArtworkPickerPresented = true
                    } label: {
                        Text("Replace")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(Color.black.opacity(0.38))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Replace playlist cover")
    }

    private var estimatedMinutes: Int {
        // Simple estimate since Song doesn’t yet have duration
        max(1, currentSongs.count * 3)
    }

    private var currentSongs: [Song] {
        shuffledSongs ?? libraryStore.songs(in: playlist.id)
    }
}

#Preview("Playlist Detail") {
    PlaylistDetailPreviewWrapper()
}

private struct PlaylistDetailPreviewWrapper: View {
    @State private var isSidebarOpen: Bool = false
    @Namespace private var chromeNS
    @State private var isBackButtonActive: Bool = true

    var body: some View {
        NavigationStack {
            PlaylistDetailView(
                playlist: Playlist(id: UUID(), name: "Workout Mix", count: 0),
                isSidebarOpen: $isSidebarOpen,
                chromeNS: chromeNS,
                isBackButtonActive: $isBackButtonActive
            )
            .environmentObject(LibraryStore())
        }
    }
}
