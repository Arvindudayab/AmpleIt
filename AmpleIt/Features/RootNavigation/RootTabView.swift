//
//  RootTabView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @EnvironmentObject private var audioPlayer: AudioPlayerService
    @State private var isSidebarOpen = false
    @State private var selectedTab: AppTab = .home

    @State private var nowPlayingID: UUID? = nil
    @State private var isSongPlayerPresented: Bool = false
    @State private var isBackButtonActive: Bool = false

    @Namespace private var chromeNS
    @Namespace private var miniPlayerNS

    private var nowPlayingSong: Song? {
        guard let nowPlayingID else { return nil }
        return libraryStore.librarySongs.first(where: { $0.id == nowPlayingID })
    }

    /// A binding that forwards play/pause toggles to the audio service.
    private var isPlayingBinding: Binding<Bool> {
        Binding(
            get: { audioPlayer.isPlaying },
            set: { newValue in newValue ? audioPlayer.play() : audioPlayer.pause() }
        )
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
                        currentPlayingSongID: nowPlayingID,
                        onPlaySong: playSong,
                        isBackButtonActive: $isBackButtonActive
                    )
                case .songs:
                    SongLibraryView(
                        isSidebarOpen: $isSidebarOpen,
                        isBackButtonActive: $isBackButtonActive,
                        chromeNS: chromeNS,
                        currentTab: .songs,
                        currentPlayingSongID: nowPlayingID,
                        onPlaySong: playSong
                    )
                case .playlists:
                    PlaylistsView(
                        isSidebarOpen: $isSidebarOpen,
                        chromeNS: chromeNS,
                        currentTab: .playlists,
                        currentPlayingSongID: nowPlayingID,
                        onPlaySong: playSong,
                        isBackButtonActive: $isBackButtonActive
                    )
                case .amp:
                    AmpView(
                        isSidebarOpen: $isSidebarOpen,
                        chromeNS: chromeNS,
                        currentSong: nowPlayingSong,
                        onOpenNowPlaying: {
                            isSongPlayerPresented = true
                        }
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
            
            // Bottom tint: subtle fade behind the mini-player
            if selectedTab != .amp {
                LinearGradient(
                    colors: [
                        Color("AppBackground").opacity(0.0),
                        Color("AppBackground").opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.container, edges: .bottom)
                .allowsHitTesting(false)
            }

            // Mini-player — always visible on non-amp tabs; idle state when no song is loaded
            if selectedTab != .amp {
                VStack {
                    Spacer()

                    ZStack(alignment: .bottom) {
                        if isBackButtonActive {
                            // Compact bar: sidebar icon + shrinking mini-player
                            HStack(spacing: 12) {
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        isSidebarOpen.toggle()
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color("AppBackground"))

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
                                .transition(
                                    .move(edge: .bottom)
                                    .combined(with: .opacity)
                                    .combined(with: .scale(scale: 0.9, anchor: .bottomTrailing))
                                )

                                MiniPlayerView(
                                    song: nowPlayingSong,
                                    isPlaying: isPlayingBinding,
                                    onTap: { isSongPlayerPresented = true },
                                    onNext: { advancePlayback() },
                                    onPrev: { stepBackPlayback() }
                                )
                                .matchedGeometryEffect(id: "miniPlayer", in: miniPlayerNS)
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            // Default: full-width mini-player
                            MiniPlayerView(
                                song: nowPlayingSong,
                                isPlaying: isPlayingBinding,
                                onTap: { isSongPlayerPresented = true },
                                onNext: { advancePlayback() },
                                onPrev: { stepBackPlayback() }
                            )
                            .matchedGeometryEffect(id: "miniPlayer", in: miniPlayerNS)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isBackButtonActive)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: nowPlayingID)
            }
        }
        .onChange(of: libraryStore.librarySongs.map(\.id)) { _, _ in
            guard let currentID = nowPlayingID else { return }
            if !libraryStore.librarySongs.contains(where: { $0.id == currentID }) {
                audioPlayer.pause()
                nowPlayingID = nil
                isSongPlayerPresented = false
            }
        }
        .onAppear {
            audioPlayer.onPlaybackFinished = { [weak audioPlayer] in
                guard audioPlayer != nil else { return }
                self.advancePlayback()
            }
        }
        .fullScreenCover(isPresented: $isSongPlayerPresented) {
            if let songID = nowPlayingID {
                SongPlayerView(
                    songID: songID,
                    queueSongs: libraryStore.queue,
                    isPlaying: isPlayingBinding,
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
                .environmentObject(audioPlayer)
            }
        }
    }

    private func advancePlayback() {
        let nextSong: Song?
        if let queued = libraryStore.popQueue() {
            nextSong = queued
        } else if !libraryStore.librarySongs.isEmpty,
                  let currentID = nowPlayingID,
                  let idx = libraryStore.librarySongs.firstIndex(where: { $0.id == currentID }) {
            nextSong = libraryStore.librarySongs[(idx + 1) % libraryStore.librarySongs.count]
        } else {
            nextSong = nil
        }
        guard let song = nextSong else { return }
        playSong(song)
    }

    private func stepBackPlayback() {
        guard !libraryStore.librarySongs.isEmpty,
              let currentID = nowPlayingID,
              let idx = libraryStore.librarySongs.firstIndex(where: { $0.id == currentID }) else { return }
        let prev = libraryStore.librarySongs[(idx - 1 + libraryStore.librarySongs.count) % libraryStore.librarySongs.count]
        playSong(prev)
    }

    private func playSong(_ song: Song) {
        audioPlayer.load(song: song)
        audioPlayer.play()
        nowPlayingID = song.id
        libraryStore.recordPlay(songID: song.id)
    }
}

#Preview {
    RootTabView()
        .environmentObject(LibraryStore())
        .environmentObject(AudioPlayerService())
}
