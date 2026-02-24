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
    @State private var isAddMenuPresented: Bool = false
    @State private var isYTUploadActive: Bool = false

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
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isAddMenuPresented.toggle()
                    }
                }
                .padding(.trailing, AppLayout.horizontalPadding)
                .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing)
                
                if isAddMenuPresented {
                    addMenuOverlay
                        .zIndex(40)
                }

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
                    .zIndex(50) // ensure it's above list + add button + mini-player
                }

                NavigationLink(
                    destination: YTUploadView(
                        isSidebarOpen: $isSidebarOpen,
                        chromeNS: chromeNS,
                        isBackButtonActive: $isBackButtonActive
                    ),
                    isActive: $isYTUploadActive
                ) {
                    EmptyView()
                }

            }
        }
    }

    private var addMenuOverlay: some View {
        ZStack {
            Rectangle()
                .fill(Color("opposite").opacity(0.18))
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .onTapGesture {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isAddMenuPresented = false
                    }
                }

            VStack(spacing: 0) {
                addMenuRow(title: "Upload from Device", systemImage: "tray.and.arrow.down") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isAddMenuPresented = false
                    }
                    // TODO: add document picker
                }
                Divider().opacity(0.6)
                addMenuRow(title: "Upload from YouTube", systemImage: "play.rectangle") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isAddMenuPresented = false
                    }
                    isYTUploadActive = true
                }
            }
            .padding(10)
            .frame(maxWidth: 240)
            .background(
                LinearGradient(
                    colors: [
                        Color("AppBackground"),
                        Color("opposite").opacity(0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 10)
            .padding(.trailing, AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing + 76)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }

    private func addMenuRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 22, alignment: .center)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))

                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.primary.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
            chromeNS: chromeNS,
            currentTab: .songs,
            isBackButtonActive: $isBackButtonActive
        )
    }
}
