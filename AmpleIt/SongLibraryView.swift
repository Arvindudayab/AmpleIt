//
//  SongLibraryView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.
//

import SwiftUI

struct SongLibraryView: View {
    @Binding var isSidebarOpen: Bool
    @Binding var isBackButtonActive: Bool
    let chromeNS: Namespace.ID
    let currentTab: AppTab

    @State private var searchText: String = ""
    @State private var actionsSong: Song? = nil

    private var filteredSongs: [Song] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return MockData.songs
        }
        let q = searchText.lowercased()
        return MockData.songs.filter {
            $0.title.lowercased().contains(q) || $0.artist.lowercased().contains(q)
        }
    }

    var body: some View {
        AppScreenContainer(
            title: currentTab.title,
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS
        ) {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(filteredSongs) { song in
                        SongCardRow(
                            song: song,
                            onEdit: { /* later */ },
                            onAddToPlaylist: { /* later */ },
                            onDelete: { /* later */ },
                            onMore: {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                                    actionsSong = song
                                }
                            }
                        )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: AppLayout.verticalRowSpacing,
                                leading: AppLayout.horizontalPadding,
                                bottom: AppLayout.verticalRowSpacing,
                                trailing: AppLayout.horizontalPadding
                            ))
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .safeAreaPadding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)

                FloatingAddButton {
                    print("Add song")
                }
                .padding(.trailing, AppLayout.horizontalPadding)
                .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing)
                
                if let song = actionsSong {
                    SongActionsOverlay(
                        song: song,
                        isPresented: Binding(
                            get: { actionsSong != nil },
                            set: { newValue in if !newValue { actionsSong = nil } }
                        ), isBackButtonActive: $isBackButtonActive,
                        onEdit: { /* later */ },
                        onAddToPlaylist: { /* later */ },
                        onDelete: { /* later */ }
                    )
                    .zIndex(50) // ensure it's above list + add button + mini-player
                }
            }
        }
    }
}

#Preview("Songs") {
    SongLibraryPreviewWrapper()
}

private struct SongLibraryPreviewWrapper: View {
    @State private var isSidebarOpen: Bool = false
    @State private var isBackButtonActive: Bool = false
    @Namespace private var chromeNS

    var body: some View {
        SongLibraryView(
            isSidebarOpen: $isSidebarOpen,
            isBackButtonActive: $isBackButtonActive,
            chromeNS: chromeNS,
            currentTab: .songs
        )
    }
}
