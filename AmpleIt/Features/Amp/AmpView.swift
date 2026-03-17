//
//  AmpView.swift
//  AmpleIt
//
//  Created by Codex on 2/23/26.
//

import SwiftUI

struct AmpView: View {
    @Binding var isSidebarOpen: Bool
    let chromeNS: Namespace.ID
    let currentSong: Song?
    let onOpenNowPlaying: () -> Void
    @State private var draftMessage: String = ""
    @FocusState private var isMessageFieldFocused: Bool

    var body: some View {
        AppScreenContainer(
            title: "Amp",
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS,
            showsTrailingPlaceholder: currentSong == nil,
            trailingToolbar: currentSong.map { song in
                AnyView(
                    Button {
                        dismissKeyboard()
                        onOpenNowPlaying()
                    } label: {
                        Group {
                            if song.artwork != nil {
                                SongArtworkView(song: song)
                            } else {
                                ArtworkPlaceholder(seed: song.id.uuidString, symbolSize: 18)
                            }
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open now playing")
                )
            }
        ) {
            VStack(spacing: 16) {
                Spacer(minLength: 12)

                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color("AppAccent").opacity(0.35),
                                        Color.primary.opacity(0.06)
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
                            .padding(14)
                    }
                    .frame(width: 96, height: 96)
                    .overlay(
                        Circle().strokeBorder(Color("AppAccent").opacity(0.6), lineWidth: 1)
                    )

                    Text("I'm Amp, ask me anything")
                        .font(.system(size: 20, weight: .semibold))
                        .multilineTextAlignment(.center)

                    Text("I can help with mixes, suggestions, and quick edits.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    chatBubble(text: "How can I make this track feel warmer?")
                    chatBubble(text: "Try boosting low mids and adding subtle tape saturation.", isUser: false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppLayout.horizontalPadding)

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    TextField("Message Amp…", text: $draftMessage)
                        .focused($isMessageFieldFocused)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
                        )

                    Button {
                        // TODO: send message to Amp
                        draftMessage = ""
                        dismissKeyboard()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color("AppAccent"))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.bottom, AppLayout.miniPlayerBottomSpacing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("AppBackground"))
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
            .simultaneousGesture(keyboardDismissGesture)
        }
    }

    private func chatBubble(text: String, isUser: Bool = true) -> some View {
        HStack {
            if isUser { Spacer() }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isUser ? Color("AppAccent") : Color.primary.opacity(0.08))
                )
            if !isUser { Spacer() }
        }
    }

    private var keyboardDismissGesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .onEnded { value in
                let isDownwardSwipe = value.translation.height > 28
                let isMostlyVertical = abs(value.translation.height) > abs(value.translation.width)
                guard isDownwardSwipe, isMostlyVertical else { return }
                dismissKeyboard()
            }
    }

    private func dismissKeyboard() {
        isMessageFieldFocused = false
    }
}

#Preview("Amp – With Song") {
    PreviewHarness { (ctx: PreviewHarness<AnyView>.Context) in
        AnyView(NavigationStack {
            AmpView(
                isSidebarOpen: ctx.isSidebarOpen,
                chromeNS: ctx.chromeNS,
                currentSong: MockData.songs.first,
                onOpenNowPlaying: {}
            )
        })
    }
}

#Preview("Amp – No Song") {
    PreviewHarness { (ctx: PreviewHarness<AnyView>.Context) in
        AnyView(NavigationStack {
            AmpView(
                isSidebarOpen: ctx.isSidebarOpen,
                chromeNS: ctx.chromeNS,
                currentSong: nil,
                onOpenNowPlaying: {}
            )
        })
    }
}
