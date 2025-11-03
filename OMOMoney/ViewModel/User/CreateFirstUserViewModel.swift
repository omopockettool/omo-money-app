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
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.userService = UserService(context: context)
        self.groupService = GroupService(context: context)
        self.userGroupService = UserGroupService(context: context)
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
            
            print("✅ Usuario, grupo, categorías y métodos de pago creados exitosamente")
            isSuccess = true
            
        } catch {
            print("❌ ERROR creando usuario: \(error.localizedDescription)")
            errorMessage = "Error creando usuario: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
}


