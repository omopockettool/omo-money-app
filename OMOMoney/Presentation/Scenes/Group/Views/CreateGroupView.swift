import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss

    let userId: UUID
    let onGroupCreated: (SDGroup) -> Void

    @State private var viewModel = GroupFormViewModel()
    @State private var groupName = ""
    @State private var selectedCurrency = "EUR"

    private let availableCurrencies = [
        ("EUR", "Euro (EUR)"),
        ("USD", "Dólar (USD)")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre del grupo", text: $groupName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Información del Grupo")
                }

                Section {
                    Picker("Moneda", selection: $selectedCurrency) {
                        ForEach(availableCurrencies, id: \.0) { currency in
                            Text(currency.1).tag(currency.0)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Configuración")
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Crear Grupo")
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
                        Task { await createGroup() }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
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
