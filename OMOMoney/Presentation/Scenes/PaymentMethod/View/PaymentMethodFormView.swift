import SwiftUI

struct PaymentMethodFormView: View {
    let group: GroupDomain
    let methodToEdit: PaymentMethodDomain?
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PaymentMethodListViewModel()

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
                    placeholder: "Nombre",
                    text: $name,
                    maxLength: 30,
                    focusedField: $nameFocused,
                    fieldValue: true
                )

                // Type picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tipo")
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
                    Text("Icono")
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
        .navigationTitle(isEditMode ? "Editar método" : "Nuevo método")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task { await save() }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
        }
        .onAppear {
            if let pm = methodToEdit {
                name = pm.name
                selectedType = pm.type
                selectedIcon = pm.icon.isEmpty ? typeIcon(pm.type) : pm.icon
            }
            nameFocused = true
        }
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let pm = methodToEdit {
            let success = await viewModel.updatePaymentMethod(pm, name: trimmed, type: selectedType, icon: selectedIcon)
            if success { onSaved(); dismiss() }
        } else {
            let success = await viewModel.createPaymentMethod(name: trimmed, type: selectedType, icon: selectedIcon, groupId: group.id)
            if success { onSaved(); dismiss() }
        }
    }

    private func typeIcon(_ type: String) -> String {
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
        case "cash":          return "Efectivo"
        case "card_debit":    return "Débito"
        case "card_credit":   return "Crédito"
        case "bank_transfer": return "Transferencia"
        default:              return type
        }
    }
}
