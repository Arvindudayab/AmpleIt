//
//  SidebarOverlay.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.
//

import SwiftUI

struct SidebarOverlay: View {
    @Binding var isOpen: Bool
    @Binding var selectedTab: AppTab
    let chromeNS: Namespace.ID

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {

                if isOpen {
                    Rectangle()
                        .fill(Color("AppBackground").opacity(0.1))
                        .ignoresSafeArea()
                        .background(.ultraThinMaterial)
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                isOpen = false
                            }
                        }
                }

                SidebarCard(
                    isOpen: $isOpen,
                    selectedTab: $selectedTab,
                    containerSize: geo.size,
                    chromeNS: chromeNS
                )
                .padding(.leading, 14)
                .padding(.top, geo.safeAreaInsets.top + 8)
            }
        }
        .allowsHitTesting(isOpen)
    }
}

private struct SidebarCard: View {
    @Binding var isOpen: Bool
    @Binding var selectedTab: AppTab
    let containerSize: CGSize
    let chromeNS: Namespace.ID

    private var openWidth: CGFloat { min(containerSize.width * 0.58, 320) }
    private var openHeight: CGFloat { min(containerSize.height * 0.50, 380) }

    var body: some View {
        // The transition and masking are applied to the whole panel.
        if isOpen {
            ZStack(alignment: .topLeading) {
                // Panel background
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    //.fill(.ultraThinMaterial)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("AppBackground").opacity(0.5),
                                Color("AppBackground").opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        //,
                        //in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
                    )

                // Content
                VStack(alignment: .leading, spacing: 14) {
                    header
                    Divider().opacity(0.7)
                    navItems
                    Spacer(minLength: 0)
                    footer
                }
                .padding(16)
            }
            .frame(width: openWidth, height: openHeight, alignment: .topLeading)
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
            // Mask + compositing prevent trailing/ghosting during move transitions.
            .mask(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .compositingGroup()
            //.transition(.opacity.combined(with: .move(edge: .leading)))
            .transition(.move(edge: .leading))
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 10) {
            Image("SoundAlphaV1")
                .resizable()
                .scaledToFit()
                .padding(8)

            VStack(alignment: .leading, spacing: 2) {
                Text("AmpleIt")
                    .font(.headline)
                Text("Navigate")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    isOpen = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .padding(10)
                    .background(.thinMaterial, in: Circle())
            }
            .accessibilityLabel("Close sidebar")
        }
    }

    // MARK: - Nav Items
    private var navItems: some View {
        VStack(alignment: .leading, spacing: 6) {
            SidebarNavRow(icon: "house.fill", title: "Home", tab: .home, selectedTab: $selectedTab) {
                closeAndSwitch(.home)
            }
            SidebarNavRow(icon: "music.note.list", title: "Songs", tab: .songs, selectedTab: $selectedTab) {
                closeAndSwitch(.songs)
            }
            SidebarNavRow(icon: "square.grid.2x2.fill", title: "Playlists", tab: .playlists, selectedTab: $selectedTab) {
                closeAndSwitch(.playlists)
            }
            SidebarNavRow(icon: "slider.horizontal.3", title: "Presets", tab: .presets, selectedTab: $selectedTab) {
                closeAndSwitch(.presets)
            }
        }
    }

    // MARK: - Footer
    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
            Text("Tip: Long-press a song for quick actions.")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.top, 6)
    }

    // MARK: - Actions
    private func closeAndSwitch(_ tab: AppTab) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            selectedTab = tab
            isOpen = false
        }
    }
}

private struct SidebarNavRow: View {
    let icon: String
    let title: String
    let tab: AppTab
    @Binding var selectedTab: AppTab
    let action: () -> Void

    private var isSelected: Bool { selectedTab == tab }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? .thinMaterial : .ultraThinMaterial)
                        .frame(width: 38, height: 38)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Sidebar – Open") {
    SidebarPreviewWrapper(isOpen: true)
}

private struct SidebarPreviewWrapper: View {
    @State var isOpen: Bool
    @State private var selectedTab: AppTab = .songs
    @Namespace private var chromeNS

    var body: some View {
        ZStack {
            // Background so blur + overlay are visible
            LinearGradient(
                colors: [
                    Color.black.opacity(0.25),
                    Color.black.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Fake app content
            VStack(alignment: .leading, spacing: 16) {
                Text("Underlying App Content")
                    .font(.title2.weight(.semibold))
                Text("Tap outside the sidebar to dismiss")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()

            // Sidebar itself
            SidebarOverlay(
                isOpen: $isOpen,
                selectedTab: $selectedTab,
                chromeNS: chromeNS
            )
        }
    }
}
