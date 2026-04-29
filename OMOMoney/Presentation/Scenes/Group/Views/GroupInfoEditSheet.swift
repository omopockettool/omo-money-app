import SwiftUI

struct GroupInfoEditSheet: View {
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    LimitedTextField(
                        icon: "person.2.fill",
                        placeholder: "Nombre del grupo",
                        text: $name,
                        maxLength: 30,
                        focusedField: $nameFocused,
                        fieldValue: true
                    )

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
                }
                .padding(AppConstants.UserInterface.padding)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Información del grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .disabled(viewModel.isLoading)
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
            .disabled(viewModel.isLoading)
            .onAppear {
                name = group.name
                selectedCurrency = group.currency
            }
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
