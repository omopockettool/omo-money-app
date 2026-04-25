import SwiftUI

struct GroupFormView: View {
    let group: SDGroup
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GroupFormViewModel()
    @State private var name = ""
    @State private var selectedCurrency = "EUR"
    @FocusState private var nameFocused: Bool?

    private let availableCurrencies = [
        ("EUR", "Euro (EUR)"),
        ("USD", "Dólar (USD)")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: Nombre
                LimitedTextField(
                    icon: "person.2.fill",
                    placeholder: "Nombre del grupo",
                    text: $name,
                    maxLength: 30,
                    focusedField: $nameFocused,
                    fieldValue: true
                )

                // MARK: Moneda
                VStack(alignment: .leading, spacing: 10) {
                    Text("Moneda")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        ForEach(availableCurrencies, id: \.0) { code, label in
                            Button {
                                withAnimation(AnimationHelper.quickSpring) { selectedCurrency = code }
                            } label: {
                                HStack {
                                    Text(label)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedCurrency == code {
                                        Image(systemName: "checkmark")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .padding(AppConstants.UserInterface.padding)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if code != availableCurrencies.last?.0 {
                                Divider()
                                    .padding(.horizontal, AppConstants.UserInterface.padding)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
                }

                // MARK: Contenido del grupo
                VStack(alignment: .leading, spacing: 10) {
                    Text("Contenido")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        NavigationLink {
                            CategoryManagementView(group: group)
                        } label: {
                            settingsRow(icon: "tag.fill", color: .orange, title: "Categorías")
                                .padding(AppConstants.UserInterface.padding)
                        }

                        Divider()
                            .padding(.horizontal, AppConstants.UserInterface.padding)

                        NavigationLink {
                            PaymentMethodManagementView(group: group)
                        } label: {
                            settingsRow(icon: "creditcard.fill", color: .blue, title: "Métodos de pago")
                                .padding(AppConstants.UserInterface.padding)
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
                }
            }
            .padding(AppConstants.UserInterface.padding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Ajustes del grupo")
        .navigationBarTitleDisplayMode(.inline)
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
        .onAppear {
            name = group.name
            selectedCurrency = group.currency
            nameFocused = true
        }
    }

    private func settingsRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if await viewModel.update(group: group, name: trimmed, currency: selectedCurrency) {
            onSaved()
            dismiss()
        }
    }
}
