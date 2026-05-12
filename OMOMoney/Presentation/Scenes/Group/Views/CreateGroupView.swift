import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss

    let userId: UUID
    let onGroupCreated: (SDGroup) -> Void

    @State private var viewModel = GroupFormViewModel()
    @State private var groupName = ""
    @State private var selectedCurrency = "EUR"
    @FocusState private var groupNameFocused: Bool?

    private var availableCurrencies: [(String, String)] {
        [
            ("EUR", LocalizationKey.Group.currencyEuro.localized),
            ("USD", LocalizationKey.Group.currencyDollar.localized)
        ]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LimitedTextField(
                        icon: "person.2.fill",
                        placeholder: LocalizationKey.Group.name.localized,
                        text: $groupName,
                        maxLength: 30,
                        focusedField: $groupNameFocused,
                        fieldValue: true
                    )
                    .textInputAutocapitalization(.words)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: 0,
                        trailing: 0
                    ))
                } header: {
                    Text(LocalizationKey.Group.info.localized)
                }

                Section {
                    Picker(LocalizationKey.Group.currency.localized, selection: $selectedCurrency) {
                        ForEach(availableCurrencies, id: \.0) { currency in
                            Text(currency.1).tag(currency.0)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(LocalizationKey.Group.settings.localized)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(LocalizationKey.Group.create.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .disabled(viewModel.isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    PrimaryToolbarCheckButton(isDisabled: groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading) {
                        Task { await createGroup() }
                    }
                }
            }
            .disabled(viewModel.isLoading)
        }
    }

    private func createGroup() async {
        let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let group = await viewModel.create(name: trimmed, currency: selectedCurrency, userId: userId) {
            onGroupCreated(group)
            dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    CreateGroupView(userId: UUID(), onGroupCreated: { _ in })
}
