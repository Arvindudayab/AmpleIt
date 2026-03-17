import SwiftUI
import PhotosUI
import UIKit

struct CreatePlaylistFormSheet: View {
    @Binding var name: String
    @Binding var artwork: ArtworkAsset?
    @Binding var showArtworkOverlay: Bool
    let onCreate: () -> Void
    let onCancel: () -> Void
    @State private var selectedArtworkItem: PhotosPickerItem? = nil
    @State private var isArtworkPickerPresented: Bool = false
    private var artworkSide: CGFloat {
        // Match form row content width so the artwork remains a true square.
        UIScreen.main.bounds.width - 32
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        // First tap reveals the overlay (Replace prompt). Actual replacement happens when
                        // the user taps the "Replace" button in the overlay.
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showArtworkOverlay = true
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.primary.opacity(0.06))

                            Group {
                                if let artworkImage = artwork?.image {
                                    artworkImage
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    ArtworkPlaceholder(seed: "new-playlist")
                                }
                            }
                            .frame(width: artworkSide, height: artworkSide)
                            .overlay {
                                if showArtworkOverlay {
                                    // Dim overlay (tap anywhere on the dim area to dismiss)
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.black.opacity(0.25))
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
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Capsule().fill(Color.black.opacity(0.35)))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(width: artworkSide, height: artworkSide)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color("AppBackground"))
                } header: {
                    Text("Artwork")
                }

                Section {
                    TextField("Playlist name", text: $name)
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
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color("AppBackground"))
                } header: {
                    Text("Name")
                }

                Section {
                    Button(action: onCreate) {
                        Text("Create")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color("AppAccent").opacity(0.25))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color("AppAccent").opacity(0.6), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .listRowBackground(Color("AppBackground"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground").ignoresSafeArea())
            .photosPicker(
                isPresented: $isArtworkPickerPresented,
                selection: $selectedArtworkItem,
                matching: .images
            )
            .onChange(of: selectedArtworkItem) { _, item in
                Task {
                    guard let item,
                          let data = try? await item.loadTransferable(type: Data.self),
                          let asset = ArtworkAsset(data: data) else { return }
                    await MainActor.run {
                        artwork = asset
                    }
                }
            }
            .navigationTitle("Create Playlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

#Preview("Create Playlist Form") {
    CreatePlaylistFormSheet(
        name: .constant(""),
        artwork: .constant(nil),
        showArtworkOverlay: .constant(false),
        onCreate: {},
        onCancel: {}
    )
}
