import CoreData
import Foundation

/// ViewModel for User list functionality
/// Handles user list display and management
@MainActor
class UserListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMoreUsers = false
    @Published var currentPage = 0
    
    // MARK: - Private Properties
    private let pageSize = 20
    private var allUsers: [User] = []
    
    // MARK: - Services
    private let userService: any UserServiceProtocol
    
    // MARK: - Initialization
    init(userService: any UserServiceProtocol) {
        self.userService = userService
    }
    
    // MARK: - Public Methods
    
    /// Load all users
    func loadUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            allUsers = try await userService.fetchUsers()
            currentPage = 0
            users = Array(allUsers.prefix(pageSize))
            hasMoreUsers = allUsers.count > pageSize
        } catch {
            errorMessage = "Error loading users: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load more users for pagination
    func loadMoreUsers() async {
        guard hasMoreUsers && !isLoading else { return }
        
        isLoading = true
        
        let nextPage = currentPage + 1
        let startIndex = nextPage * pageSize
        let endIndex = min(startIndex + pageSize, allUsers.count)
        
        if startIndex < allUsers.count {
            let newUsers = Array(allUsers[startIndex..<endIndex])
            users.append(contentsOf: newUsers)
            currentPage = nextPage
            hasMoreUsers = endIndex < allUsers.count
        }
        
        isLoading = false
    }
    
    /// Reset pagination and reload from beginning
    func resetPagination() async {
        currentPage = 0
        users = Array(allUsers.prefix(pageSize))
        hasMoreUsers = allUsers.count > pageSize
    }
    
    /// Create a new user
    func createUser(name: String, email: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let newUser = try await userService.createUser(name: name, email: email)
            allUsers.append(newUser)
            allUsers.sort { ($0.name ?? "") < ($1.name ?? "") }
            
            // Reset pagination to show the new user
            await resetPagination()
            
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
            allUsers.removeAll { $0.id == user.id }
            users.removeAll { $0.id == user.id }
            
            // Adjust pagination if needed
            if users.isEmpty && hasMoreUsers {
                await loadMoreUsers()
            }
            
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
