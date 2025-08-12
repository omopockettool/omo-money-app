import Foundation
import CoreData

/// ViewModel for Detailed Group functionality
/// Handles group detail display, user management, and entry display
@MainActor
class DetailedGroupViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedGroup: Group?
    @Published var groupTotal: NSDecimalNumber = NSDecimalNumber.zero
    @Published var isCalculatingTotal = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Group Creation State
    @Published var isCreatingGroup = false
    @Published var groupCreationError: String?
    @Published var groupCreationSuccess = false
    @Published var shouldNavigateBack = false
    
    // MARK: - Services
    private let userService: UserService
    private let groupService: GroupService
    private let userGroupService: UserGroupService
    private let entryService: EntryService
    private let itemService: ItemService
    private let categoryService: CategoryService
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.userService = UserService(context: context)
        self.groupService = GroupService(context: context)
        self.userGroupService = UserGroupService(context: context)
        self.entryService = EntryService(context: context)
        self.itemService = ItemService(context: context)
        self.categoryService = CategoryService(context: context)
    }
    
    // MARK: - Public Methods
    
    /// Load data for the application
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        // Load initial data if needed
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
    
    /// Get entries for a specific group
    func entries(for group: Group) async -> [Entry] {
        guard let groupId = group.id else { return [] }
        
        do {
            return try await entryService.getEntries(for: group)
        } catch {
            errorMessage = "Error loading entries: \(error.localizedDescription)"
            return []
        }
    }
    
    /// Calculate total spent for a specific group
    func totalSpent(for group: Group) async -> NSDecimalNumber {
        guard let groupId = group.id else { return NSDecimalNumber.zero }
        
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
            let userGroup = try await userGroupService.createUserGroup(user: user, group: newGroup, role: "owner")
            
            // Update state
            selectedGroup = newGroup
            groupCreationSuccess = true
            shouldNavigateBack = true
            
        } catch {
            groupCreationError = "Error creating group: \(error.localizedDescription)"
        }
        
        isCreatingGroup = false
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
