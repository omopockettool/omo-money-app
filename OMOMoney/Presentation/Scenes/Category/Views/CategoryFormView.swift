import SwiftUI
import OSLog

struct CategoryFormView: View {
    let group: SDGroup
    let categoryToEdit: SDCategory?
    let onSaved: (SDCategory) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CategoryFormViewModel()

    @State private var debugNodeID = UUID()
    @State private var name = ""
    @State private var selectedColor = "#0A84FF"
    @State private var selectedIcon = "tag.fill"
    @FocusState private var nameFocused: Bool?

    private var isEditMode: Bool { categoryToEdit != nil }

    private let colorOptions = [
        "#FF453A", "#FF9F0A", "#FFD60A", "#30D158",
        "#0A84FF", "#5E5CE6", "#BF5AF2", "#FF375F",
        "#64D2FF", "#FF6B35", "#4ECDC4", "#95A5A6"
    ]

    private let iconOptions = [
        "cart.fill", "fork.knife", "car.fill", "house.fill",
        "gamecontroller.fill", "tshirt.fill", "heart.fill", "book.fill",
        "airplane", "bus.fill", "pill.fill", "dog.fill",
        "music.note", "dumbbell.fill", "bag.fill", "gift.fill",
        "tag.fill", "star.fill", "bolt.fill", "leaf.fill",
        "cup.and.saucer.fill", "tv.fill", "phone.fill", "wifi"
    ]

    private static let logger = Logger(subsystem: "OMOMoney", category: "Lifecycle.CategoryFormView")

    init(group: SDGroup, categoryToEdit: SDCategory?, onSaved: @escaping (SDCategory) -> Void) {
        self.group = group
        self.categoryToEdit = categoryToEdit
        self.onSaved = onSaved

        _name = State(wrappedValue: categoryToEdit?.name ?? "")
        _selectedColor = State(wrappedValue: categoryToEdit?.color ?? "#0A84FF")
        _selectedIcon = State(wrappedValue: categoryToEdit?.icon ?? "tag.fill")
        Self.logger.debug("init editMode=\(categoryToEdit != nil) initialName=\(categoryToEdit?.name ?? "")")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CenteredEditorNameBlock(
                    icon: "textformat",
                    placeholder: LocalizationKey.Category.name.localized,
                    text: $name,
                    maxLength: 20,
                    focusedField: $nameFocused,
                    fieldValue: true
                ) {
                    ZStack {
                        Circle()
                            .fill((Color(hex: selectedColor) ?? .accentColor).opacity(0.15))
                            .frame(width: 72, height: 72)
                        Image(systemName: selectedIcon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(Color(hex: selectedColor) ?? .accentColor)
                    }
                    .animation(AnimationHelper.quickSpring, value: selectedColor)
                    .animation(AnimationHelper.quickSpring, value: selectedIcon)
                }

                // Color picker
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizationKey.Category.color.localized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .accentColor)
                                .frame(height: 36)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: selectedColor == hex ? 3 : 0)
                                )
                                .shadow(color: (Color(hex: hex) ?? .clear).opacity(0.4), radius: selectedColor == hex ? 4 : 0)
                                .onTapGesture {
                                    withAnimation(AnimationHelper.quickSpring) { selectedColor = hex }
                                }
                        }
                    }
                    .padding(AppConstants.UserInterface.padding)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
                }

                // Icon picker
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizationKey.Category.icon.localized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(iconOptions, id: \.self) { icon in
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedIcon == icon ? (Color(hex: selectedColor) ?? .accentColor) : Color(.tertiarySystemGroupedBackground))
                                    .frame(height: 44)
                                Image(systemName: icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(selectedIcon == icon ? .white : .secondary)
                            }
                            .onTapGesture {
                                withAnimation(AnimationHelper.quickSpring) { selectedIcon = icon }
                            }
                        }
                    }
                    .padding(AppConstants.UserInterface.padding)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
                }
            }
            .padding(AppConstants.UserInterface.padding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isEditMode ? LocalizationKey.Category.edit.localized : LocalizationKey.Category.new.localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            Self.logger.debug("node appeared nodeID=\(self.debugNodeID.uuidString) editMode=\(self.categoryToEdit != nil) draftName=\(self.name) color=\(self.selectedColor) icon=\(self.selectedIcon)")
        }
        .onDisappear {
            Self.logger.debug("node disappeared nodeID=\(self.debugNodeID.uuidString) draftName=\(self.name) color=\(self.selectedColor) icon=\(self.selectedIcon)")
        }
        .onChange(of: name) { _, newValue in
            Self.logger.debug("draft name changed nodeID=\(self.debugNodeID.uuidString) value=\(newValue)")
        }
        .onChange(of: selectedColor) { _, newValue in
            Self.logger.debug("draft color changed nodeID=\(self.debugNodeID.uuidString) value=\(newValue)")
        }
        .onChange(of: selectedIcon) { _, newValue in
            Self.logger.debug("draft icon changed nodeID=\(self.debugNodeID.uuidString) value=\(newValue)")
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task { await save() }
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
        }
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        Self.logger.debug("save tapped editMode=\(categoryToEdit != nil) trimmedName=\(trimmed)")
        if let saved = await viewModel.save(name: trimmed, color: selectedColor, icon: selectedIcon, groupId: group.id, categoryToEdit: categoryToEdit) {
            Self.logger.debug("save succeeded savedName=\(saved.name)")
            onSaved(saved)
            dismiss()
        } else {
            Self.logger.debug("save failed editMode=\(categoryToEdit != nil)")
        }
    }
}
