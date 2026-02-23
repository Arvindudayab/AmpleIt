//
//  RootTabView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.
//

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
    @State private var isSidebarOpen = false
    @State private var selectedTab: AppTab = .home

    // Mini-player mock state (wire to your real player later)
    @State private var nowPlaying: Song? = MockData.songs.first
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
                        chromeNS: chromeNS,
                        currentTab: .songs,
                        isBackButtonActive: $isBackButtonActive
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
            //.animation(.easeInOut(duration: 0.18), value: isSidebarOpen)

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
                                                LinearGradient(
                                                    colors: [
                                                        Color("AppBackground"),
                                                        Color("AppAccent")
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                            )
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
                                        if let idx = MockData.songs.firstIndex(where: { $0.id == song.id }) {
                                            let next = MockData.songs[(idx + 1) % MockData.songs.count]
                                            nowPlaying = next
                                        }
                                    },
                                    onPrev: {
                                        if let idx = MockData.songs.firstIndex(where: { $0.id == song.id }) {
                                            let prev = MockData.songs[(idx - 1 + MockData.songs.count) % MockData.songs.count]
                                            nowPlaying = prev
                                        }
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
                                    if let idx = MockData.songs.firstIndex(where: { $0.id == song.id }) {
                                        let next = MockData.songs[(idx + 1) % MockData.songs.count]
                                        nowPlaying = next
                                    }
                                },
                                onPrev: {
                                    if let idx = MockData.songs.firstIndex(where: { $0.id == song.id }) {
                                        let prev = MockData.songs[(idx - 1 + MockData.songs.count) % MockData.songs.count]
                                        nowPlaying = prev
                                    }
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
//            if let song = nowPlaying {
//                VStack {
//                    Spacer()
//                    MiniPlayerView(
//                        song: song,
//                        isPlaying: $isPlaying,
//                        onTap: {
//                            // Open full player later
//                            print("Mini-player tapped")
//                        },
//                        onNext: {
//                            // demo next
//                            if let idx = MockData.songs.firstIndex(where: { $0.id == song.id }) {
//                                let next = MockData.songs[(idx + 1) % MockData.songs.count]
//                                nowPlaying = next
//                            }
//                        },
//                        onPrev: {
//                            if let idx = MockData.songs.firstIndex(where: { $0.id == song.id }) {
//                                let prev = MockData.songs[(idx - 1 + MockData.songs.count) % MockData.songs.count]
//                                nowPlaying = prev
//                            }
//                        }
//                    )
//
//                    .padding(.horizontal, 14)
//                    .padding(.bottom, 12)
//                }
//                .transition(.move(edge: .bottom).combined(with: .opacity))
//                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: nowPlaying?.id)
//            }
        }
    }
}

#Preview {
    RootTabView()
}
