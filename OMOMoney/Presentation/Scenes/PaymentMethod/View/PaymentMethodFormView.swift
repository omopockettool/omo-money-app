import SwiftUI
import OSLog

struct PaymentMethodFormView: View {
    let group: SDGroup
    let methodToEdit: SDPaymentMethod?
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PaymentMethodFormViewModel()

    @State private var debugNodeID = UUID()
    @State private var name = ""
    @State private var selectedType = "card_debit"
    @State private var selectedIcon = "creditcard.fill"
    @FocusState private var nameFocused: Bool?

    private let types = ["cash", "card_debit", "card_credit", "bank_transfer"]
    private let iconOptions = [
        "creditcard.fill", "banknote.fill", "arrow.left.arrow.right", "iphone",
        "dollarsign.circle.fill", "eurosign.circle.fill", "bag.fill", "gift.fill",
        "building.columns.fill", "qrcode", "wallet.pass.fill", "checkmark.seal.fill"
    ]
    private var isEditMode: Bool { methodToEdit != nil }

    private static let logger = Logger(subsystem: "OMOMoney", category: "Lifecycle.PaymentMethodFormView")

    init(group: SDGroup, methodToEdit: SDPaymentMethod?, onSaved: @escaping () -> Void) {
        self.group = group
        self.methodToEdit = methodToEdit
        self.onSaved = onSaved

        _name = State(wrappedValue: methodToEdit?.name ?? "")
        _selectedType = State(wrappedValue: methodToEdit?.type ?? "card_debit")
        _selectedIcon = State(
            wrappedValue: {
                guard let methodToEdit else { return "creditcard.fill" }
                return methodToEdit.icon.isEmpty ? Self.defaultTypeIcon(for: methodToEdit.type) : methodToEdit.icon
            }()
        )
        Self.logger.debug("init editMode=\(methodToEdit != nil) initialName=\(methodToEdit?.name ?? "") initialType=\(methodToEdit?.type ?? "card_debit")")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Preview
                ZStack {
                    Circle()
                        .fill(typeColor(selectedType).opacity(0.15))
                        .frame(width: 72, height: 72)
                    Image(systemName: selectedIcon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(typeColor(selectedType))
                }
                .animation(AnimationHelper.quickSpring, value: selectedType)
                .animation(AnimationHelper.quickSpring, value: selectedIcon)

                // Name
                LimitedTextField(
                    icon: "textformat",
                    placeholder: LocalizationKey.Payment.name.localized,
                    text: $name,
                    maxLength: 30,
                    focusedField: $nameFocused,
                    fieldValue: true
                )

                // Type picker
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizationKey.Payment.type.localized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        ForEach(types, id: \.self) { type in
                            Button {
                                withAnimation(AnimationHelper.quickSpring) { selectedType = type }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: typeIcon(type))
                                        .font(.system(size: 16))
                                        .foregroundStyle(selectedType == type ? .white : typeColor(type))
                                    Text(typeName(type))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(selectedType == type ? .white : .primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer()
                                }
                                .padding(AppConstants.UserInterface.padding)
                                .background(selectedType == type ? typeColor(type) : Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Icon picker
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizationKey.Payment.icon.localized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(iconOptions, id: \.self) { icon in
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedIcon == icon ? typeColor(selectedType) : Color(.tertiarySystemGroupedBackground))
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
        .navigationTitle(isEditMode ? LocalizationKey.Payment.editMethod.localized : LocalizationKey.Payment.newMethod.localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            Self.logger.debug("node appeared nodeID=\(self.debugNodeID.uuidString) editMode=\(self.methodToEdit != nil) draftName=\(self.name) type=\(self.selectedType) icon=\(self.selectedIcon)")
        }
        .onDisappear {
            Self.logger.debug("node disappeared nodeID=\(self.debugNodeID.uuidString) draftName=\(self.name) type=\(self.selectedType) icon=\(self.selectedIcon)")
        }
        .onChange(of: name) { _, newValue in
            Self.logger.debug("draft name changed nodeID=\(self.debugNodeID.uuidString) value=\(newValue)")
        }
        .onChange(of: selectedType) { _, newValue in
            Self.logger.debug("draft type changed nodeID=\(self.debugNodeID.uuidString) value=\(newValue)")
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

        Self.logger.debug("save tapped editMode=\(methodToEdit != nil) trimmedName=\(trimmed) selectedType=\(selectedType)")
        if await viewModel.save(name: trimmed, type: selectedType, icon: selectedIcon, groupId: group.id, methodToEdit: methodToEdit) {
            Self.logger.debug("save succeeded editMode=\(methodToEdit != nil)")
            onSaved()
            dismiss()
        } else {
            Self.logger.debug("save failed editMode=\(methodToEdit != nil)")
        }
    }

    private func typeIcon(_ type: String) -> String {
        Self.defaultTypeIcon(for: type)
    }

    private static func defaultTypeIcon(for type: String) -> String {
        switch type {
        case "cash":          return "banknote.fill"
        case "bank_transfer": return "arrow.left.arrow.right"
        case "card_credit":   return "creditcard.fill"
        default:              return "creditcard.fill"
        }
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "cash":          return .green
        case "bank_transfer": return .orange
        case "card_credit":   return .purple
        default:              return .blue
        }
    }

    private func typeName(_ type: String) -> String {
        switch type {
        case "cash":          return LocalizationKey.Payment.cash.localized
        case "card_debit":    return LocalizationKey.Payment.debit.localized
        case "card_credit":   return LocalizationKey.Payment.credit.localized
        case "bank_transfer": return LocalizationKey.Payment.transfer.localized
        default:              return type
        }
    }
}
