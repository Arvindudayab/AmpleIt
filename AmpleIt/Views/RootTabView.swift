//
//  RootTabView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home, songs, playlists, amp
    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .songs: return "Songs"
        case .playlists: return "Playlists"
        case .amp: return "Amp"
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @State private var isSidebarOpen = false
    @State private var selectedTab: AppTab = .home

    // Mini-player mock state (wire to your real player later)
    @State private var nowPlaying: Song? = nil
    @State private var isPlaying: Bool = true
    
    @State private var isBackButtonActive: Bool = false

    @Namespace private var chromeNS
    @Namespace private var miniPlayerNS 

    var body: some View {
        ZStack {
            // Active screen (NO TabView => no bottom tab bar)
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        isSidebarOpen: $isSidebarOpen,
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
            if nowPlaying != nil { 
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
            if let song = nowPlaying {
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
                                    onTap: { print("Mini-player tapped") },
                                    onNext: {
                                        advancePlayback(from: song)
                                    },
                                    onPrev: {
                                        stepBackPlayback(from: song)
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
                                onTap: { print("Mini-player tapped") },
                                onNext: {
                                    advancePlayback(from: song)
                                },
                                onPrev: {
                                    stepBackPlayback(from: song)
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
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: nowPlaying?.id)
            }
        }
        .onAppear {
            if nowPlaying == nil {
                nowPlaying = libraryStore.librarySongs.first
            }
        }
        .onChange(of: libraryStore.librarySongs.map(\.id)) { _, _ in
            let songs = libraryStore.librarySongs
            guard let current = nowPlaying else {
                nowPlaying = songs.first
                return
            }
            if !songs.contains(where: { $0.id == current.id }) {
                nowPlaying = songs.first
            }
        }
    }

    private func advancePlayback(from current: Song) {
        if let queued = libraryStore.popQueue() {
            nowPlaying = queued
            return
        }
        guard !libraryStore.librarySongs.isEmpty,
              let idx = libraryStore.librarySongs.firstIndex(where: { $0.id == current.id }) else { return }
        let next = libraryStore.librarySongs[(idx + 1) % libraryStore.librarySongs.count]
        nowPlaying = next
    }

    private func stepBackPlayback(from current: Song) {
        guard !libraryStore.librarySongs.isEmpty,
              let idx = libraryStore.librarySongs.firstIndex(where: { $0.id == current.id }) else { return }
        let prev = libraryStore.librarySongs[(idx - 1 + libraryStore.librarySongs.count) % libraryStore.librarySongs.count]
        nowPlaying = prev
    }
}

#Preview {
    RootTabView()
        .environmentObject(LibraryStore())
}
