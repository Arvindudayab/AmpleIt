import SwiftUI

struct AmpView: View {
    @Binding var isSidebarOpen: Bool
    let chromeNS: Namespace.ID
    let currentSong: Song?
    let onOpenNowPlaying: () -> Void
    var onPlaySong: ((Song) -> Void)? = nil

    @EnvironmentObject private var libraryStore: LibraryStore
    @StateObject private var agent = AmpAgent()
    @State private var draftMessage: String = ""
    @State private var dotPhase: Bool = false
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        AppScreenContainer(
            title: "Amp",
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS,
            showsTrailingPlaceholder: currentSong == nil,
            trailingToolbar: currentSong.map { song in
                AnyView(
                    Button {
                        isFieldFocused = false
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
            VStack(spacing: 0) {
                if agent.messages.isEmpty {
                    emptyState
                } else {
                    chatScrollView
                }
                inputBar
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("AppBackground"))
            .contentShape(Rectangle())
            .onTapGesture { isFieldFocused = false }
            .simultaneousGesture(dismissGesture)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 12)
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color("AppAccent").opacity(0.35), Color.primary.opacity(0.06)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                    Image("SoundAlphaV1")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.primary)
                        .padding(14)
                }
                .frame(width: 96, height: 96)
                .overlay(Circle().strokeBorder(Color("AppAccent").opacity(0.6), lineWidth: 1))

                Text("I'm Amp, ask me anything")
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)

                Text("I can queue music, tweak your EQ, and build playlists.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Chat

    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(agent.messages) { msg in
                        messageBubble(msg).id(msg.id)
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)
            }
            .onChange(of: agent.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: agent.messages.last?.text) { _, _ in
                if agent.isThinking { scrollToBottom(proxy: proxy) }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = agent.messages.last else { return }
        withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(last.id, anchor: .bottom) }
    }

    @ViewBuilder
    private func messageBubble(_ msg: AmpAgent.Message) -> some View {
        HStack {
            if msg.role == .user { Spacer(minLength: 40) }
            if msg.role == .assistant && msg.text.isEmpty && msg.isStreaming {
                thinkingDotsView
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(msg.text)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(msg.role == .user
                                  ? Color("AppAccent")
                                  : Color.primary.opacity(0.08))
                    )
                    .frame(maxWidth: .infinity, alignment: msg.role == .user ? .trailing : .leading)
            }
            if msg.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var thinkingDotsView: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.primary.opacity(0.5))
                    .frame(width: 7, height: 7)
                    .offset(y: dotPhase ? -3 : 3)
                    .animation(
                        .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: dotPhase
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.primary.opacity(0.08)))
        .onAppear { dotPhase = true }
        .onDisappear { dotPhase = false }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message Amp…", text: $draftMessage, axis: .vertical)
                .lineLimit(1...5)
                .focused($isFieldFocused)
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
                .onSubmit { sendMessage() }

            Button { sendMessage() } label: {
                Image(systemName: agent.isThinking ? "ellipsis.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(canSend ? Color.primary : Color.primary.opacity(0.25))
//                    .background {
//                        if canSend {
//                            Circle()
//                                .fill(Color.primary)
//                                .frame(width: 22, height: 22)
//                        }
//                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, AppLayout.horizontalPadding)
        .padding(.vertical, 10)
        .padding(.bottom, AppLayout.miniPlayerBottomSpacing)
    }

    private func sendMessage() {
        let text = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !agent.isThinking else { return }
        draftMessage = ""
        isFieldFocused = false
        Task { await agent.send(text: text, store: libraryStore, currentNowPlayingID: currentSong?.id, onPlaySong: onPlaySong) }
    }

    private var canSend: Bool {
        !draftMessage.trimmingCharacters(in: .whitespaces).isEmpty && !agent.isThinking
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .onEnded { value in
                guard value.translation.height > 28,
                      abs(value.translation.height) > abs(value.translation.width) else { return }
                isFieldFocused = false
            }
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
