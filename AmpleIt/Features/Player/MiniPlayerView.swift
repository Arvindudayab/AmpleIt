//
//  MiniPlayerView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.
//

import SwiftUI

struct MiniPlayerView: View {
    let song: Song?
    @Binding var isPlaying: Bool
    let onTap: () -> Void
    let onNext: () -> Void
    let onPrev: () -> Void

    private var isIdle: Bool { song == nil }

    var body: some View {
        HStack(spacing: 12) {
            artwork
            titles
            Spacer(minLength: 8)
            controls
        }
        .padding(12)
        .background(background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color("AppAccent"), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 10)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { if !isIdle { onTap() } }
    }

    private var artwork: some View {
        Group {
            if let song {
                SongArtworkView(song: song)
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .frame(width: 46, height: 46)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(song?.title ?? "Now Playing")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isIdle ? .secondary : .primary)
                .lineLimit(1)

            if let artist = song?.artist {
                Text(artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button(action: onPrev) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(isIdle)
            .opacity(isIdle ? 0.3 : 1)

            Button {
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(isIdle)
            .opacity(isIdle ? 0.3 : 1)

            Button(action: onNext) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(isIdle)
            .opacity(isIdle ? 0.3 : 1)
        }
        .foregroundStyle(.primary)
    }

    private var background: LinearGradient {
        // Match the app's accent/gradient language used elsewhere (e.g., add button)
        LinearGradient(
            colors: [
                Color("AppBackground"),
                Color("opposite").opacity(0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}


#Preview("Mini Player – Active") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()
        VStack {
            Spacer()
            MiniPlayerView(
                song: MockData.songs.first!,
                isPlaying: .constant(true),
                onTap: {},
                onNext: {},
                onPrev: {}
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
    }
}

#Preview("Mini Player – Idle") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()
        VStack {
            Spacer()
            MiniPlayerView(
                song: nil,
                isPlaying: .constant(false),
                onTap: {},
                onNext: {},
                onPrev: {}
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
    }
}
