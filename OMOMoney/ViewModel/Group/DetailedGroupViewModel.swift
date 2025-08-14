import CoreData
import Foundation

/// ViewModel for Detailed Group functionality
/// Handles group detail display, user management, and entry display
@MainActor
class DetailedGroupViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedUser: User?
    @Published var selectedGroup: Group?
    @Published var groupTotal = NSDecimalNumber.zero
    @Published var isCalculatingTotal = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var users: [User] = []
    @Published var groups: [Group] = []
    @Published var entries: [Entry] = []
    
    // MARK: - Group Creation State
    @Published var isCreatingGroup = false
    @Published var groupCreationError: String?
    @Published var groupCreationSuccess = false
    @Published var shouldNavigateBack = false
    
    // MARK: - Services
    let context: NSManagedObjectContext
    private let userService: any UserServiceProtocol
    private let groupService: any GroupServiceProtocol
    private let userGroupService: any UserGroupServiceProtocol
    private let entryService: any EntryServiceProtocol
    private let itemService: any ItemServiceProtocol
    private let categoryService: any CategoryServiceProtocol
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext, userService: any UserServiceProtocol, groupService: any GroupServiceProtocol, userGroupService: any UserGroupServiceProtocol, entryService: any EntryServiceProtocol, itemService: any ItemServiceProtocol, categoryService: any CategoryServiceProtocol) {
        self.context = context
        self.userService = userService
        self.groupService = groupService
        self.userGroupService = userGroupService
        self.entryService = entryService
        self.itemService = itemService
        self.categoryService = categoryService
    }
    
    // MARK: - Public Methods
    
    /// Load data for the application
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load users and groups
            users = try await userService.fetchUsers()
            groups = try await groupService.fetchGroups()
            
            // Create default user if none exist
            if users.isEmpty {
                let defaultUser = try await userService.createUser(name: "Usuario Principal", email: "usuario@omomoney.com")
                users = [defaultUser]
            }
            
            // Create default group if none exist
            if groups.isEmpty && !users.isEmpty {
                guard let firstUser = users.first else { return }
                let defaultGroup = try await groupService.createGroup(name: "Grupo Principal", currency: "USD")
                _ = try await userGroupService.createUserGroup(user: firstUser, group: defaultGroup, role: "owner")
                groups = [defaultGroup]
            }
        } catch {
            errorMessage = "Error loading data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Get user groups for a specific group
    func userGroups(for group: Group) async -> [UserGroup] {
        do {
            return try await userGroupService.getUserGroups(for: group)
        } catch {
            errorMessage = "Error loading user groups: \(error.localizedDescription)"
            return []
        }
    }
    
    /// Get groups for a specific user
    func groups(for user: User) async -> [Group] {
        do {
            return try await userGroupService.getGroups(for: user)
        } catch {
            errorMessage = "Error loading user groups: \(error.localizedDescription)"
            return []
        }
    }
    
    /// Auto-select first user and first group
    func autoSelectFirstUserAndGroup() async {
        guard !users.isEmpty else { return }
        
        // Auto-select first user
        guard let firstUser = users.first else { return }
        selectedUser = firstUser
        
        // Get groups for the first user
        let userGroups = await groups(for: firstUser)
        
        if let firstGroup = userGroups.first {
            selectedGroup = firstGroup
            // Load entries and calculate total for the selected group
            await calculateTotalForGroup(firstGroup)
        }
    }
    
    /// Select a user and load their groups
    func selectUser(_ user: User) async {
        selectedUser = user
        selectedGroup = nil // Reset selected group
        
        // Load groups for the selected user (we don't need to store them separately as we can filter them when needed)
        _ = await groups(for: user)
    }
    
    /// Get entries for a specific group
    func entries(for group: Group) async -> [Entry] {
        guard group.id != nil else { return [] }
        
        do {
            return try await entryService.getEntries(for: group)
        } catch {
            errorMessage = "Error loading entries: \(error.localizedDescription)"
            return []
        }
    }
    
    /// Calculate total spent for a specific group
    func totalSpent(for group: Group) async -> NSDecimalNumber {
        guard group.id != nil else { return NSDecimalNumber.zero }
        
        do {
            return try await itemService.calculateTotalAmount(for: group)
        } catch {
            errorMessage = "Error calculating total: \(error.localizedDescription)"
            return NSDecimalNumber.zero
        }
    }
    
    /// Calculate total for a specific group
    func calculateTotalForGroup(_ group: Group) async {
        isCalculatingTotal = true
        errorMessage = nil
        
        do {
            groupTotal = try await itemService.calculateTotalAmount(for: group)
            entries = try await entryService.getEntries(for: group)
        } catch {
            errorMessage = "Error calculating total: \(error.localizedDescription)"
        }
        
        isCalculatingTotal = false
    }
    
    /// Calculate total in background
    func calculateTotalInBackground(for group: Group) async {
        await calculateTotalForGroup(group)
    }
    
    /// Create a new group
    func createGroup(name: String, currency: String, user: User) async {
        isCreatingGroup = true
        groupCreationError = nil
        groupCreationSuccess = false
        
        do {
            // Create the group
            let newGroup = try await groupService.createGroup(name: name, currency: currency)
            
            // Create the user-group relationship
            _ = try await userGroupService.createUserGroup(user: user, group: newGroup, role: "owner")
            
            // Update state
            selectedGroup = newGroup
            groupCreationSuccess = true
            shouldNavigateBack = true
            
        } catch {
            groupCreationError = "Error creating group: \(error.localizedDescription)"
        }
        
        isCreatingGroup = false
    }
    
    /// Create default user for first-time setup
    func createDefaultUser() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let defaultUser = try await userService.createUser(name: "Usuario Principal", email: "usuario@omomoney.com")
            users = [defaultUser]
            
            // Create default group
            let defaultGroup = try await groupService.createGroup(name: "Grupo Principal", currency: "USD")
            _ = try await userGroupService.createUserGroup(user: defaultUser, group: defaultGroup, role: "owner")
            groups = [defaultGroup]
            
            // Select the default group
            selectedGroup = defaultGroup
        } catch {
            errorMessage = "Error creating default user: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Create test user for development/testing
    func createTestUser() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create test user with random data
            let testNames = ["Juan Pérez", "María García", "Carlos López", "Ana Martínez", "Luis Rodríguez"]
            let testEmails = ["juan@test.com", "maria@test.com", "carlos@test.com", "ana@test.com", "luis@test.com"]
            
            let randomIndex = Int.random(in: 0..<testNames.count)
            let testName = testNames[randomIndex]
            let testEmail = testEmails[randomIndex]
            
            let testUser = try await userService.createUser(name: testName, email: testEmail)
            users.append(testUser)
            
            // Create test group if none exist
            if groups.isEmpty {
                let testGroup = try await groupService.createGroup(name: "Grupo de Prueba", currency: "USD")
                _ = try await userGroupService.createUserGroup(user: testUser, group: testGroup, role: "owner")
                groups = [testGroup]
                
                // Select the test group
                selectedGroup = testGroup
            }
            
            // Create some test categories
            let testCategories = [
                ("Comida", "#FF6B6B"),
                ("Transporte", "#4ECDC4"),
                ("Entretenimiento", "#45B7D1"),
                ("Compras", "#96CEB4"),
                ("Salud", "#FFEAA7")
            ]
            
            for (categoryName, categoryColor) in testCategories {
                guard let firstGroup = groups.first else { continue }
                _ = try await categoryService.createCategory(name: categoryName, color: categoryColor, group: firstGroup)
            }
            
        } catch {
            errorMessage = "Error creating test user: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Format currency for display
    func formatCurrency(_ amount: NSDecimalNumber, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: amount) ?? "\(amount) \(currency)"
    }
    
    /// Clear group creation state
    func clearGroupCreationState() {
        groupCreationError = nil
        groupCreationSuccess = false
        shouldNavigateBack = false
        isCreatingGroup = false
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
