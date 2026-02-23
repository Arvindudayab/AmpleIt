//
//  HomeView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.
//

import SwiftUI

private struct HomeSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("See all") {}
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            content
        }
    }
}


struct HomeView: View {
    @Binding var isSidebarOpen: Bool
    let chromeNS: Namespace.ID
    let currentTab: AppTab
    @Binding var isBackButtonActive: Bool

    private let recentlyAdded = Array(MockData.songs.prefix(5))
    private let recentlyPlayed = Array(MockData.songs.prefix(5))
    @State private var actionsSong: Song? = nil

    var body: some View {
        AppScreenContainer(
            title: currentTab.title,
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS
        ) {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        HomeSection(title: "Recently Added") {
                            VStack(spacing: 10) {
                                ForEach(recentlyAdded) { song in
                                    SongCardRow(
                                        song: song,
                                        onMore: {
                                            withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                                                actionsSong = song
                                            }
                                        }
                                    )
                                }
                            }
                        }

                        HomeSection(title: "Recently Played") {
                            VStack(spacing: 10) {
                                ForEach(recentlyPlayed) { song in
                                    SongCardRow(
                                        song: song,
                                        onMore: {
                                            withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                                                actionsSong = song
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
                .safeAreaPadding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)

                if let song = actionsSong {
                    SongActionsOverlay(
                        song: song,
                        isPresented: Binding(
                            get: { actionsSong != nil },
                            set: { newValue in if !newValue { actionsSong = nil } }
                        ),
                        isBackButtonActive: $isBackButtonActive,
                        onEdit: { /* later */ },
                        onAddToQueue: { /* later */ },
                        onAddToPlaylist: { /* later */ },
                        onDelete: { /* later */ }
                    )
                    .zIndex(50)
                }
            }
        }
    }
}

#Preview("Home") {
    HomePreviewWrapper()
}

private struct HomePreviewWrapper: View {
    @State private var isSidebarOpen: Bool = false
    @State private var isBackButtonActive: Bool = false
    @Namespace private var chromeNS

    var body: some View {
        HomeView(
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS,
            currentTab: .home,
            isBackButtonActive: $isBackButtonActive
        )
    }
}
