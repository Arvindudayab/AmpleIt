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

    private let recentlyAdded = Array(MockData.songs.prefix(5))
    private let recentlyPlayed = Array(MockData.songs.prefix(5))

    var body: some View {
        AppScreenContainer(
            title: currentTab.title,
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HomeSection(title: "Recently Added") {
                        VStack(spacing: 10) {
                            ForEach(recentlyAdded) { song in
                                SongCardRow(song: song)
                            }
                        }
                    }

                    HomeSection(title: "Recently Played") {
                        VStack(spacing: 10) {
                            ForEach(recentlyPlayed) { song in
                                SongCardRow(song: song)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
            .safeAreaPadding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)
        }
    }
}

#Preview("Home") {
    PreviewHarness { ctx in
        HomeView(
            isSidebarOpen: ctx.isSidebarOpen,
            chromeNS: ctx.chromeNS,
            currentTab: .home
        )
    }
}
