import Foundation
import CoreData
import SwiftUI

@MainActor
class CreateFirstUserViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    private let context: NSManagedObjectContext
    private let userService: any UserServiceProtocol
    private let groupService: any GroupServiceProtocol
    private let userGroupService: any UserGroupServiceProtocol
    private let categoryService: any CategoryServiceProtocol
    
    init() {
        self.context = PersistenceController.shared.container.viewContext
        self.userService = UserService(context: context)
        self.groupService = GroupService(context: context)
        self.userGroupService = UserGroupService(context: context)
        self.categoryService = CategoryService(context: context)
    }
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@")
    }
    
    func createUser() async {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Crear usuario
            let user = try await userService.createUser(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            // Crear grupo por defecto
            let group = try await groupService.createGroup(
                name: "Personal",
                currency: "USD"
            )
            
            // Crear relación usuario-grupo
            _ = try await userGroupService.createUserGroup(
                user: user,
                group: group,
                role: "owner"
            )
            
            // Crear categorías por defecto
            let defaultCategories = [
                ("Comida", "#FF6B6B"),
                ("Transporte", "#4ECDC4"),
                ("Entretenimiento", "#45B7D1"),
                ("Compras", "#96CEB4"),
                ("Salud", "#FFEAA7"),
                ("Otros", "#DDA0DD")
            ]
            
            for (name, color) in defaultCategories {
                _ = try await categoryService.createCategory(
                    name: name,
                    color: color,
                    group: group
                )
            }
            
            print("✅ Usuario, grupo y categorías creados exitosamente")
            isSuccess = true
            
        } catch {
            print("❌ ERROR creando usuario: \(error.localizedDescription)")
            errorMessage = "Error creando usuario: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
}


