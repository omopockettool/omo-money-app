import Foundation
import CoreData
import SwiftUI

@MainActor
class ManageGroupsViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let context: NSManagedObjectContext
    private let groupService: any GroupServiceProtocol
    private let userGroupService: any UserGroupServiceProtocol
    private let selectedUser: User
    
    init(selectedUser: User) {
        // Obtener el contexto de Core Data
        self.context = PersistenceController.shared.container.viewContext
        self.groupService = GroupService(context: context)
        self.userGroupService = UserGroupService(context: context)
        self.selectedUser = selectedUser
    }
    
    /// Cargar grupos del usuario actual
    func loadUserGroups() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Obtener los grupos del usuario seleccionado
            let userGroups = try await userGroupService.getUserGroups(for: selectedUser)
            
            // Extraer los grupos de las relaciones UserGroup y filtrar por validez
            let validGroups: [Group] = userGroups.compactMap { userGroup in
                guard let group = userGroup.group,
                      !group.isDeleted,
                      !group.objectID.isTemporaryID else {
                    return nil
                }
                return group
            }
            
            await MainActor.run {
                self.groups = validGroups
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error al cargar grupos: \(error.localizedDescription)"
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    /// Eliminar un grupo
    func deleteGroup(_ group: Group) {
        Task {
            do {
                // Verificar que el grupo sea válido
                guard !group.isDeleted && !group.objectID.isTemporaryID else {
                    await MainActor.run {
                        self.errorMessage = "No se puede eliminar un grupo inválido"
                        self.showError = true
                    }
                    return
                }
                
                // Eliminar el grupo
                try await groupService.deleteGroup(group)
                
                // Recargar la lista
                await loadUserGroups()
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error al eliminar grupo: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
    
    /// Limpiar mensaje de error
    func clearError() {
        errorMessage = nil
        showError = false
    }
}

// Preview no disponible para ViewModels
