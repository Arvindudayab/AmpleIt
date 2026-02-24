import SwiftUI
import PhotosUI
import UIKit

struct CreatePlaylistFormSheet: View {
    @Binding var name: String
    @Binding var artwork: Image?
    @Binding var showArtworkOverlay: Bool
    let onCreate: () -> Void
    let onDone: () -> Void
    @State private var selectedArtworkItem: PhotosPickerItem? = nil
    @State private var isArtworkPickerPresented: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showArtworkOverlay = true
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.primary.opacity(0.06))

                                Group {
                                    if let artwork {
                                        artwork
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .clipped()
                                    } else {
                                        ArtworkPlaceholder(seed: "new-playlist")
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay {
                                    if showArtworkOverlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.black.opacity(0.25))
                                            .onTapGesture {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    showArtworkOverlay = false
                                                }
                                            }

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
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
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
                          let uiImage = UIImage(data: data) else { return }
                    await MainActor.run {
                        artwork = Image(uiImage: uiImage)
                    }
                }
            }
            .navigationTitle("Create Playlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                }
            }
        }
    }
}
