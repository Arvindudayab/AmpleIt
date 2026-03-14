//
//  RootTabView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @State private var isSidebarOpen = false
    @State private var selectedTab: AppTab = .home

    // Mini-player mock state (wire to your real player later)
    @State private var nowPlayingID: UUID? = nil
    @State private var isPlaying: Bool = true
    @State private var isSongPlayerPresented: Bool = false
    
    @State private var isBackButtonActive: Bool = false

    @Namespace private var chromeNS
    @Namespace private var miniPlayerNS 

    private var nowPlayingSong: Song? {
        guard let nowPlayingID else { return nil }
        return libraryStore.librarySongs.first(where: { $0.id == nowPlayingID })
    }

    var body: some View {
        ZStack {
            // Active screen (NO TabView => no bottom tab bar)
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        isSidebarOpen: $isSidebarOpen,
                        selectedTab: $selectedTab,
                        chromeNS: chromeNS,
                        currentTab: .home,
                        isBackButtonActive: $isBackButtonActive
                    )
                case .songs:
                    SongLibraryView(
                        isSidebarOpen: $isSidebarOpen,
                        isBackButtonActive: $isBackButtonActive,
                        chromeNS: chromeNS,
                        currentTab: .songs
                    )
                case .playlists:
                    PlaylistsView(
                        isSidebarOpen: $isSidebarOpen,
                        chromeNS: chromeNS,
                        currentTab: .playlists,
                        isBackButtonActive: $isBackButtonActive
                    )
                case .amp:
                    AmpView(
                        isSidebarOpen: $isSidebarOpen,
                        chromeNS: chromeNS
                    )
                }
            }
            .blur(radius: isSidebarOpen ? 10 : 0)

            // Sidebar overlays everything
            SidebarOverlay(
                isOpen: $isSidebarOpen,
                selectedTab: $selectedTab,
                chromeNS: chromeNS
            )
            
            // Bottom tint (Option 2): subtle fade behind the mini-player
            if nowPlayingSong != nil { 
                LinearGradient(
                    colors: [
                        Color("opposite").opacity(0.0),
                        Color("opposite").opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.container, edges: .bottom)
                .allowsHitTesting(false)
                .transition(.opacity)
            }

            // Mini-player floating above bottom safe area
            if let song = nowPlayingSong {
                VStack {
                    Spacer()

                    ZStack(alignment: .bottom) {
                        if isBackButtonActive {
                            // Playlist-only: compact bar (icon + shrinking mini-player)
                            HStack(spacing: 12) {
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        isSidebarOpen.toggle()
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                Color("AppBackground")
                                        )

                                        Image("SoundAlphaV1")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(.primary)
                                            .padding(.top, 8)
                                    }
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Circle().strokeBorder(Color("AppAccent"), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Open sidebar")
                                // Animate icon appearing
                                .transition(
                                    .move(edge: .bottom)
                                    .combined(with: .opacity)
                                    .combined(with: .scale(scale: 0.9, anchor: .bottomTrailing))
                                )

                                MiniPlayerView(
                                    song: song,
                                    isPlaying: $isPlaying,
                                    onTap: {
                                        isSongPlayerPresented = true
                                    },
                                    onNext: {
                                        advancePlayback()
                                    },
                                    onPrev: {
                                        stepBackPlayback()
                                    }
                                )
                                // Matched-geometry makes the mini-player smoothly shrink/reposition
                                .matchedGeometryEffect(id: "miniPlayer", in: miniPlayerNS)
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            // Default: full-width mini-player
                            MiniPlayerView(
                                song: song,
                                isPlaying: $isPlaying,
                                onTap: {
                                    isSongPlayerPresented = true
                                },
                                onNext: {
                                    advancePlayback()
                                },
                                onPrev: {
                                    stepBackPlayback()
                                }
                            )
                            .matchedGeometryEffect(id: "miniPlayer", in: miniPlayerNS)
                        }
                    }
                    // Keep the bottom position consistent with the rest of the app
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                    // Drive the layout change animation
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isBackButtonActive)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: nowPlayingID)
            }
        }
        .onAppear {
            if nowPlayingID == nil {
                nowPlayingID = libraryStore.librarySongs.first?.id
            }
        }
        .onChange(of: libraryStore.librarySongs.map(\.id)) { _, _ in
            let songs = libraryStore.librarySongs
            guard let currentID = nowPlayingID else {
                nowPlayingID = songs.first?.id
                return
            }
            if !songs.contains(where: { $0.id == currentID }) {
                nowPlayingID = songs.first?.id
            }
        }
        .fullScreenCover(isPresented: $isSongPlayerPresented) {
            if let songID = nowPlayingID {
                SongPlayerView(
                    songID: songID,
                    queueSongs: libraryStore.queue,
                    isPlaying: $isPlaying,
                    onClose: {
                        isSongPlayerPresented = false
                    },
                    onNext: {
                        advancePlayback()
                    },
                    onPrev: {
                        stepBackPlayback()
                    }
                )
                .environmentObject(libraryStore)
            }
        }
    }

    private func advancePlayback() {
        if let queued = libraryStore.popQueue() {
            nowPlayingID = queued.id
            return
        }
        guard !libraryStore.librarySongs.isEmpty,
              let currentID = nowPlayingID,
              let idx = libraryStore.librarySongs.firstIndex(where: { $0.id == currentID }) else { return }
        let next = libraryStore.librarySongs[(idx + 1) % libraryStore.librarySongs.count]
        nowPlayingID = next.id
    }

    private func stepBackPlayback() {
        guard !libraryStore.librarySongs.isEmpty,
              let currentID = nowPlayingID,
              let idx = libraryStore.librarySongs.firstIndex(where: { $0.id == currentID }) else { return }
        let prev = libraryStore.librarySongs[(idx - 1 + libraryStore.librarySongs.count) % libraryStore.librarySongs.count]
        nowPlayingID = prev.id
    }
}

#Preview {
    RootTabView()
        .environmentObject(LibraryStore())
}
