import SwiftUI

struct GroupInfoEditSheet: View {
    let group: SDGroup
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GroupFormViewModel()
    @State private var name = ""
    @State private var selectedCurrency = "EUR"
    @FocusState private var nameFocused: Bool?

    private var availableCurrencies: [(String, String)] {
        [
            ("EUR", LocalizationKey.Group.currencyEuro.localized),
            ("USD", LocalizationKey.Group.currencyDollar.localized)
        ]
    }

    init(group: SDGroup, onSaved: @escaping () -> Void) {
        self.group = group
        self.onSaved = onSaved

        _name = State(wrappedValue: group.name)
        _selectedCurrency = State(wrappedValue: group.currency)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LimitedTextField(
                        icon: "person.2.fill",
                        placeholder: LocalizationKey.Group.name.localized,
                        text: $name,
                        maxLength: 30,
                        focusedField: $nameFocused,
                        fieldValue: true
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: 0,
                        trailing: 0
                    ))
                }

                Section(LocalizationKey.Group.currency.localized) {
                    ForEach(availableCurrencies, id: \.0) { code, label in
                        Button {
                            withAnimation(AnimationHelper.quickSpring) { selectedCurrency = code }
                        } label: {
                            HStack {
                                Text(label)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedCurrency == code {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .navigationTitle(LocalizationKey.Group.info.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .disabled(viewModel.isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    PrimaryToolbarCheckButton(isDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading) {
                        Task { await save() }
                    }
                }
            }
            .disabled(viewModel.isLoading)
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
