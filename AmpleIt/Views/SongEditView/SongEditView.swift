//
//  SongEditView.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 1/16/26.
//

import SwiftUI
import PhotosUI
import UIKit

struct SongEditView: View {
    @Binding var isBackButtonActive: Bool
    @Environment(\.dismiss) private var dismiss

    // MARK: - Editable Fields (local draft state)
    @State private var title: String = "Midnight Echoes"
    @State private var artist: String = "Arvind"

    // Artwork: store a picked image; nil means placeholder
    @State private var artworkImage: Image? = nil
    @State private var showArtworkOverlay: Bool = false
    @State private var selectedArtworkItem: PhotosPickerItem? = nil
    @State private var isArtworkPickerPresented: Bool = false

    // Presets
    private let presets: [String] = ["Default", "Warm", "Bass Boost", "Lo-Fi", "Vocal Clarity"]
    @State private var selectedPreset: String = "Default"

    // Levels
    @State private var speed: Double = 1.0
    @State private var reverb: Double = 0.0
    @State private var bass: Double = 0.0
    @State private var mid: Double = 0.0
    @State private var treble: Double = 0.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                artworkSection

                metadataSection
                
                Divider()

                presetsRow

                modifiersSection

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.top, 18)
            .padding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)
        }
        .background(
            Color("AppBackground")
                .ignoresSafeArea())
        .simultaneousGesture(backSwipeGesture)
        .onAppear {
            isBackButtonActive = true
        }
        .onDisappear {
            showArtworkOverlay = false
            isBackButtonActive = false
        }
        .photosPicker(
            isPresented: $isArtworkPickerPresented,
            selection: $selectedArtworkItem,
            matching: .images
        )
        .onChange(of: selectedArtworkItem) { _, item in
            Task {
                guard let item,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { return }
                await MainActor.run {
                    artworkImage = Image(uiImage: uiImage)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // Discard changes
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

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // TODO: persist changes to your model/store
                    handleBack()
                } label: {
                    Text("Save")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
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

    // MARK: - Sections

    private var artworkSection: some View {
        let artworkSize: CGFloat = 220
        return Button {
            // First tap reveals the overlay (Replace prompt). Actual replacement happens when
            // the user taps the "Replace" button in the overlay.
            withAnimation(.easeInOut(duration: 0.15)) {
                showArtworkOverlay = true
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.primary.opacity(0.06))

                Group {
                    if let artworkImage {
                        artworkImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: artworkSize, height: artworkSize)
                            .clipped()
                    } else {
                        ArtworkPlaceholder(seed: "edit")
                    }
                }
                .frame(width: artworkSize, height: artworkSize)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    if showArtworkOverlay {
                        // Dim overlay (tap anywhere on the dim area to dismiss)
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color("opposite").opacity(0.25))
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    showArtworkOverlay = false
                                }
                            }

                        // Replace button
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showArtworkOverlay = false
                            }
                            isArtworkPickerPresented = true
                        } label: {
                            Text("Replace")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.35))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(width: artworkSize, height: artworkSize)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Replace artwork")
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Song Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Title", text: $title)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
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

            VStack(alignment: .leading, spacing: 6) {
                Text("Artist")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Artist", text: $artist)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
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
    }

    private var presetsRow: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(presets, id: \ .self) { p in
                    Button {
                        selectedPreset = p
                    } label: {
                        Text(p)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(selectedPreset)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            Spacer()

            Button {
                // TODO: persist preset
                print("Save preset: \(selectedPreset)")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Save Preset")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            //.buttonStyle(.plain)
        }
    }

    private var modifiersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Levels")
                .font(.headline.weight(.semibold))

            LevelSlider(title: "Speed", value: $speed, range: 0.25...4.0, format: { String(format: "%.2fx", $0) })
            LevelSlider(title: "Reverb", value: $reverb, range: 0.0...1.0, format: { String(format: "%.0f%%", $0 * 100) })
            LevelSlider(title: "Bass", value: $bass, range: -12.0...12.0, format: { String(format: "%+.0f dB", $0) })
            LevelSlider(title: "Mid", value: $mid, range: -12.0...12.0, format: { String(format: "%+.0f dB", $0) })
            LevelSlider(title: "Treble", value: $treble, range: -12.0...12.0, format: { String(format: "%+.0f dB", $0) })
        }
        .padding(14)
    }
}

#Preview("Song Edit") {
    NavigationStack {
        SongEditView(isBackButtonActive: .constant(false))
    }
}
