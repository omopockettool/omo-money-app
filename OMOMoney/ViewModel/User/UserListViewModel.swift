import Foundation
import CoreData

/// ViewModel for User list functionality
/// Handles user list display and management
@MainActor
class UserListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let userService: UserService
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.userService = UserService(context: context)
    }
    
    // MARK: - Public Methods
    
    /// Load all users
    func loadUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            users = try await userService.fetchUsers()
        } catch {
            errorMessage = "Error loading users: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Create a new user
    func createUser(name: String, email: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let newUser = try await userService.createUser(name: name, email: email)
            users.append(newUser)
            users.sort { ($0.name ?? "") < ($1.name ?? "") }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating user: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete a user
    func deleteUser(_ user: User) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await userService.deleteUser(user)
            users.removeAll { $0.id == user.id }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting user: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Check if user name exists
    func userExists(withName name: String, excluding userId: UUID? = nil) async -> Bool {
        do {
            return try await userService.userExists(withName: name, excluding: userId)
        } catch {
            errorMessage = "Error checking user name: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Get users count
    func getUsersCount() async -> Int {
        do {
            return try await userService.getUsersCount()
        } catch {
            errorMessage = "Error getting users count: \(error.localizedDescription)"
            return 0
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
