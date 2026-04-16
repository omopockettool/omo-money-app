//
//  CreateGroupView.swift
//  OMOMoney
//
//  Created by System on 15/11/25.
//

import SwiftUI

/// Vista para crear un nuevo grupo
/// ✅ Clean Architecture: Uses Use Cases, no direct Core Data access
struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss

    // ✅ Clean Architecture: Use Cases instead of Core Data context
    let createGroupUseCase: CreateGroupUseCase
    let createUserGroupUseCase: CreateUserGroupUseCase
    let userId: UUID
    let onGroupCreated: (SDGroup) -> Void  // ✅ Clean Architecture: Domain callback
    
    @State private var groupName: String = ""
    @State private var selectedCurrency: String = "EUR"
    @State private var isCreating: Bool = false
    @State private var errorMessage: String?
    
    // Lista de monedas disponibles
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
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Crear Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        Task {
                            await createGroup()
                        }
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                }
            }
            .disabled(isCreating)
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func createGroup() async {
        guard !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "El nombre del grupo no puede estar vacío"
            return
        }

        isCreating = true
        errorMessage = nil

        do {
            // ✅ Clean Architecture: Use CreateGroupUseCase
            // This will create the group with default categories and payment methods
            let groupDomain = try await createGroupUseCase.execute(
                name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
                currency: selectedCurrency
            )

            print("✅ CreateGroupView: Group created via Use Case: '\(groupDomain.name)'")

            // ✅ Clean Architecture: Use CreateUserGroupUseCase to associate user with group
            let _ = try await createUserGroupUseCase.execute(
                userId: userId,
                groupId: groupDomain.id,
                role: "owner"
            )

            print("✅ CreateGroupView: User-Group association created via Use Case")

            // ✅ Notify parent with Domain model (already in Domain form from Use Case)
            onGroupCreated(groupDomain)

            // Cerrar sheet
            dismiss()

        } catch {
            errorMessage = "Error al crear grupo: \(error.localizedDescription)"
            isCreating = false
        }
    }
}

// MARK: - Preview
#Preview {
    let appContainer = AppDIContainer.shared
    return CreateGroupView(
        createGroupUseCase: appContainer.makeCreateGroupUseCase(),
        createUserGroupUseCase: appContainer.makeCreateUserGroupUseCase(),
        userId: UUID(),
        onGroupCreated: { _ in }
    )
}
