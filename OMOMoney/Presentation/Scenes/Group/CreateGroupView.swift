//
//  CreateGroupView.swift
//  OMOMoney
//
//  Created by System on 15/11/25.
//

import SwiftUI
import CoreData

/// Vista para crear un nuevo grupo
struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    
    let context: NSManagedObjectContext
    let userId: UUID
    let onGroupCreated: (Group) -> Void
    
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
            let groupService = GroupService(context: context)
            let userGroupService = UserGroupService(context: context)
            let userService = UserService(context: context)
            
            // Obtener el usuario
            guard let user = try await userService.fetchUser(by: userId) else {
                errorMessage = "Usuario no encontrado"
                isCreating = false
                return
            }
            
            // Crear el grupo
            let newGroup = try await groupService.createGroup(
                name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
                currency: selectedCurrency
            )
            
            // Asociar usuario con el grupo
            _ = try await userGroupService.createUserGroup(
                user: user,
                group: newGroup,
                role: "owner"
            )
            
            // Notificar al padre
            onGroupCreated(newGroup)
            
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
    CreateGroupView(
        context: PersistenceController.preview.container.viewContext,
        userId: UUID(),
        onGroupCreated: { _ in }
    )
}
