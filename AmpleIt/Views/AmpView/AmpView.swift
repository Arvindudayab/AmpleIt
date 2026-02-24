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
    @State private var draftMessage: String = ""

    var body: some View {
        AppScreenContainer(
            title: "Amp",
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS
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
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color("AppAccent"))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("AppBackground"))
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

}

#Preview("Amp") {
    AmpPreviewWrapper()
}

private struct AmpPreviewWrapper: View {
    @State private var isSidebarOpen: Bool = false
    @Namespace private var chromeNS

    var body: some View {
        NavigationStack {
            AmpView(
                isSidebarOpen: $isSidebarOpen,
                chromeNS: chromeNS
            )
        }
    }
}
