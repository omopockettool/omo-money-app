import SwiftUI

struct GroupFormView: View {
    let group: SDGroup
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedCurrency = "EUR"
    @State private var isSaving = false
    @FocusState private var nameFocused: Bool?

    private let updateGroupUseCase: UpdateGroupUseCase = AppDIContainer.shared.makeUpdateGroupUseCase()

    private let availableCurrencies = [
        ("EUR", "Euro (EUR)"),
        ("USD", "Dólar (USD)")
    ]

    var body: some View {
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
                                withAnimation(AnimationHelper.quickSpring) {
                                    selectedCurrency = code
                                }
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
        .navigationTitle("Editar grupo")
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
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
        .onAppear {
            name = group.name
            selectedCurrency = group.currency
            nameFocused = true
        }
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        group.name = trimmed
        group.currency = selectedCurrency
        group.lastModifiedAt = Date()
        do {
            try await updateGroupUseCase.execute(group: group)
            onSaved()
            dismiss()
        } catch {
            isSaving = false
        }
    }
}
