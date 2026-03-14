//
//  YTUploadView.swift
//  AmpleIt
//
//  Created by Codex on 2/22/26.
//

import SwiftUI

struct YTUploadView: View {
    @Binding var isSidebarOpen: Bool
    let chromeNS: Namespace.ID
    @Binding var isBackButtonActive: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var youtubeLink: String = ""
    @State private var statusMessage: String = ""
    @State private var isConverting: Bool = false
    @FocusState private var isLinkFocused: Bool

    var body: some View {
        AppScreenContainer(
            title: "YouTube Upload",
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS,
            wrapInNavigationStack: false,
            showsSidebarButton: false
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    linkInput
                    convertButton
                    status
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.top, 18)
                .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)
            }
            .safeAreaPadding(.top, 2)
            .navigationBarBackButtonHidden(true)
            .simultaneousGesture(backSwipeGesture)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        handleBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                }
            }
            .onAppear {
                statusMessage = ""
                isBackButtonActive = true
            }
            .onDisappear {
                isBackButtonActive = false
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YouTube to MP3")
                .font(.system(size: 28, weight: .bold))
            Text("Paste a YouTube link to convert and download the audio.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var linkInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YouTube Link")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("https://www.youtube.com/watch?v=…", text: $youtubeLink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.URL)
                .textContentType(.URL)
                .focused($isLinkFocused)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.primary.opacity(0.10), lineWidth: 1)
                )
        }
    }

    private var convertButton: some View {
        Button {
            startConversion()
        } label: {
            HStack(spacing: 10) {
                if isConverting {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(isConverting ? "Converting…" : "Convert & Download")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.primary)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("AppAccent").opacity(0.28),
                                Color.primary.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color("AppAccent").opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isConverting || youtubeLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var status: some View {
        Group {
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func startConversion() {
        let trimmed = youtubeLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isConverting = true
        statusMessage = "Starting conversion…"
        isLinkFocused = false

        // TODO: Integrate a backend conversion endpoint and download handler.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isConverting = false
            statusMessage = "Conversion request queued. Connect the downloader to complete."
        }
    }

    private var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                guard value.startLocation.x < 28 else { return }
                guard value.translation.width > 100 else { return }
                guard abs(value.translation.height) < 60 else { return }
                handleBack()
            }
    }

    private func handleBack() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            isBackButtonActive = false
        }
        dismiss()
    }
}

#Preview("YouTube Upload") {
    YTUploadPreviewWrapper()
}

private struct YTUploadPreviewWrapper: View {
    @State private var isSidebarOpen: Bool = false
    @State private var isBackButtonActive: Bool = false
    @Namespace private var chromeNS

    var body: some View {
        NavigationStack {
            YTUploadView(
                isSidebarOpen: $isSidebarOpen,
                chromeNS: chromeNS,
                isBackButtonActive: $isBackButtonActive
            )
        }
    }
}
