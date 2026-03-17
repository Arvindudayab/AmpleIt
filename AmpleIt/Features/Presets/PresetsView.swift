import SwiftUI

struct PresetsView: View {
    @Binding var isSidebarOpen: Bool
    let chromeNS: Namespace.ID
    @EnvironmentObject private var libraryStore: LibraryStore

    @State private var editingPreset: SongPreset? = nil
    @State private var isCreatePresented: Bool = false

    var body: some View {
        AppScreenContainer(
            title: "Presets",
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS,
            showsTrailingPlaceholder: false,
            trailingToolbar: AnyView(
                Button {
                    isCreatePresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 36, height: 36)
                }
            )
        ) {
            List {
                Section {
                    ForEach(SongPreset.builtIn) { preset in
                        PresetRow(preset: preset, isBuiltIn: true, onTap: {})
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: AppLayout.verticalRowSpacing,
                                leading: AppLayout.horizontalPadding,
                                bottom: AppLayout.verticalRowSpacing,
                                trailing: AppLayout.horizontalPadding
                            ))
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    PresetsViewSectionHeader(title: "Built-In")
                }

                if !libraryStore.userPresets.isEmpty {
                    Section {
                        ForEach(libraryStore.userPresets) { preset in
                            PresetRow(preset: preset, isBuiltIn: false, onTap: {
                                editingPreset = preset
                            })
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: AppLayout.verticalRowSpacing,
                                leading: AppLayout.horizontalPadding,
                                bottom: AppLayout.verticalRowSpacing,
                                trailing: AppLayout.horizontalPadding
                            ))
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                libraryStore.deleteUserPreset(id: libraryStore.userPresets[index].id)
                            }
                        }
                    } header: {
                        PresetsViewSectionHeader(title: "My Presets")
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .safeAreaPadding(.bottom, AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset)
        }
        .sheet(isPresented: $isCreatePresented) {
            PresetFormSheet(preset: nil) { newPreset in
                libraryStore.addUserPreset(newPreset)
            }
        }
        .sheet(item: $editingPreset) { preset in
            PresetFormSheet(preset: preset) { updated in
                libraryStore.updateUserPreset(updated)
            }
        }
    }
}

// MARK: - Preset Row

private struct PresetRow: View {
    let preset: SongPreset
    let isBuiltIn: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                    Image(systemName: isBuiltIn ? "lock.fill" : "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.name)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if !isBuiltIn {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isBuiltIn)
    }

    private var subtitle: String {
        var parts: [String] = []
        if preset.speed != 1.0 { parts.append(String(format: "%.2fx", preset.speed)) }
        if preset.pitch != 0   { parts.append(String(format: "Pitch %+.0f st", preset.pitch)) }
        if preset.bass != 0    { parts.append(String(format: "Bass %+.0f dB", preset.bass)) }
        if preset.reverb > 0   { parts.append(String(format: "Reverb %.0f%%", preset.reverb * 100)) }
        return parts.isEmpty ? "Default levels" : parts.joined(separator: " · ")
    }
}

// MARK: - Section Header

private struct PresetsViewSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.top, 8)
            .listRowInsets(EdgeInsets())
            .textCase(nil)
    }
}

// MARK: - Preset Form Sheet

struct PresetFormSheet: View {
    let preset: SongPreset?
    let onSave: (SongPreset) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var speed: Double
    @State private var pitch: Double
    @State private var reverb: Double
    @State private var bass: Double
    @State private var mid: Double
    @State private var treble: Double

    init(preset: SongPreset?, onSave: @escaping (SongPreset) -> Void) {
        self.preset = preset
        self.onSave = onSave
        _name   = State(initialValue: preset?.name   ?? "")
        _speed  = State(initialValue: preset?.speed  ?? 1.0)
        _pitch  = State(initialValue: preset?.pitch  ?? 0.0)
        _reverb = State(initialValue: preset?.reverb ?? 0.0)
        _bass   = State(initialValue: preset?.bass   ?? 0.0)
        _mid    = State(initialValue: preset?.mid    ?? 0.0)
        _treble = State(initialValue: preset?.treble ?? 0.0)
    }

    private var isEditing: Bool { preset != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preset Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("e.g. My Preset", text: $name)
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

                    Divider()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Levels")
                            .font(.headline.weight(.semibold))

                        LevelSlider(title: "Speed", value: $speed, range: 0.25...4.0, step: 0.05, format: {
                            String(format: "%.2fx", $0)
                        })
                        LevelSlider(title: "Pitch", value: $pitch, range: -12.0...12.0, step: 1.0, format: {
                            let st = Int($0)
                            return st == 0 ? "0 st" : String(format: "%+d st", st)
                        })
                        LevelSlider(title: "Reverb", value: $reverb, range: 0.0...1.0, format: {
                            String(format: "%.0f%%", $0 * 100)
                        })
                        LevelSlider(title: "Bass", value: $bass, range: -12.0...12.0, format: {
                            String(format: "%+.0f dB", $0)
                        })
                        LevelSlider(title: "Mid", value: $mid, range: -12.0...12.0, format: {
                            String(format: "%+.0f dB", $0)
                        })
                        LevelSlider(title: "Treble", value: $treble, range: -12.0...12.0, format: {
                            String(format: "%+.0f dB", $0)
                        })
                    }
                    .padding(14)
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Preset" : "New Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(SongPreset(
                            id: preset?.id ?? UUID(),
                            name: trimmed,
                            speed: speed,
                            pitch: pitch,
                            reverb: reverb,
                            bass: bass,
                            mid: mid,
                            treble: treble
                        ))
                        dismiss()
                    }
                    .disabled(!canSave)
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}
