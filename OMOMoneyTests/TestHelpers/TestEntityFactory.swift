import Foundation
import CoreData
@testable import OMOMoney

/// Factory for creating test entities in unit tests
/// Provides convenient methods to create test data
class TestEntityFactory {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - User Factory Methods
    
    /// Create a test user
    func createUser(name: String = "Test User", email: String = "test@example.com") -> User {
        let user = User(context: context)
        user.id = UUID()
        user.name = name
        user.email = email
        user.createdAt = Date()
        user.lastModifiedAt = Date()
        return user
    }
    
    /// Create multiple test users
    func createUsers(count: Int, prefix: String = "User") -> [User] {
        return (0..<count).map { index in
            createUser(
                name: "\(prefix) \(index + 1)",
                email: "\(prefix.lowercased())\(index + 1)@example.com"
            )
        }
    }
    
    // MARK: - Group Factory Methods
    
    /// Create a test group
    func createGroup(name: String = "Test Group", currency: String = "USD") -> Group {
        let group = Group(context: context)
        group.id = UUID()
        group.name = name
        group.currency = currency
        group.createdAt = Date()
        group.lastModifiedAt = Date()
        return group
    }
    
    /// Create multiple test groups
    func createGroups(count: Int, prefix: String = "Group") -> [Group] {
        return (0..<count).map { index in
            createGroup(
                name: "\(prefix) \(index + 1)",
                currency: index % 2 == 0 ? "USD" : "EUR"
            )
        }
    }
    
    // MARK: - Category Factory Methods
    
    /// Create a test category
    func createCategory(name: String = "Test Category", color: String = "#007AFF", group: Group? = nil) -> OMOMoney.Category {
        let category = Category(context: context)
        category.id = UUID()
        category.name = name
        category.color = color
        category.group = group
        category.createdAt = Date()
        category.lastModifiedAt = Date()
        return category
    }
    
    /// Create multiple test categories
    func createCategories(count: Int, prefix: String = "Category", group: Group? = nil) -> [OMOMoney.Category] {
        let colors = ["#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE"]
        return (0..<count).map { index in
            createCategory(
                name: "\(prefix) \(index + 1)",
                color: colors[index % colors.count],
                group: group
            )
        }
    }
    
    // MARK: - Entry Factory Methods
    
    /// Create a test entry
    func createEntry(description: String = "Test Entry", date: Date = Date(), category: OMOMoney.Category? = nil, group: Group? = nil) -> Entry {
        let entry = Entry(context: context)
        entry.id = UUID()
        entry.entryDescription = description
        entry.date = date
        entry.category = category
        entry.group = group
        entry.createdAt = Date()
        entry.lastModifiedAt = Date()
        return entry
    }
    
    /// Create multiple test entries
    func createEntries(count: Int, prefix: String = "Entry", category: OMOMoney.Category? = nil, group: Group? = nil) -> [Entry] {
        return (0..<count).map { index in
            createEntry(
                description: "\(prefix) \(index + 1)",
                date: Date().addingTimeInterval(TimeInterval(-index * 86400)), // Each entry one day apart
                category: category,
                group: group
            )
        }
    }
    
    // MARK: - Item Factory Methods
    
    /// Create a test item
    func createItem(description: String = "Test Item", amount: NSDecimalNumber = NSDecimalNumber(value: 10.0), quantity: Int32 = 1, entry: Entry? = nil) -> Item {
        let item = Item(context: context)
        item.id = UUID()
        item.itemDescription = description
        item.amount = amount
        item.quantity = quantity
        item.entry = entry
        item.createdAt = Date()
        item.lastModifiedAt = Date()
        return item
    }
    
    /// Create multiple test items
    func createItems(count: Int, prefix: String = "Item", entry: Entry? = nil) -> [Item] {
        return (0..<count).map { index in
            createItem(
                description: "\(prefix) \(index + 1)",
                amount: NSDecimalNumber(value: Double(index + 1) * 5.0),
                quantity: Int32(index + 1),
                entry: entry
            )
        }
    }
    
    // MARK: - UserGroup Factory Methods
    
    /// Create a test user group relationship
    func createUserGroup(user: User, group: Group, role: String = "member") -> UserGroup {
        let userGroup = UserGroup(context: context)
        userGroup.id = UUID()
        userGroup.user = user
        userGroup.group = group
        userGroup.role = role
        userGroup.joinedAt = Date()
        return userGroup
    }
    
    /// Create multiple test user group relationships
    func createUserGroups(users: [User], groups: [Group], role: String = "member") -> [UserGroup] {
        var userGroups: [UserGroup] = []
        
        for (index, user) in users.enumerated() {
            let group = groups[index % groups.count]
            userGroups.append(createUserGroup(user: user, group: group, role: role))
        }
        
        return userGroups
    }
    
    // MARK: - Complex Scenarios
    
    /// Create a complete test scenario with users, groups, categories, entries, and items
    func createCompleteTestScenario() -> (users: [User], groups: [Group], categories: [OMOMoney.Category], entries: [Entry], items: [Item], userGroups: [UserGroup]) {
        // Create users
        let users = createUsers(count: 3)
        
        // Create groups
        let groups = createGroups(count: 2)
        
        // Create categories for each group
        var allCategories: [OMOMoney.Category] = []
        for group in groups {
            let groupCategories = createCategories(count: 3, group: group)
            allCategories.append(contentsOf: groupCategories)
        }
        
        // Create entries for each group
        var allEntries: [Entry] = []
        for group in groups {
            let groupEntries = createEntries(count: 5, group: group)
            allEntries.append(contentsOf: groupEntries)
        }
        
        // Create items for each entry
        var allItems: [Item] = []
        for entry in allEntries {
            let entryItems = createItems(count: 2, entry: entry)
            allItems.append(contentsOf: entryItems)
        }
        
        // Create user group relationships
        let userGroups = createUserGroups(users: users, groups: groups)
        
        return (users, groups, allCategories, allEntries, allItems, userGroups)
    }
    
    // MARK: - Cleanup
    
    /// Clean up all test entities
    func cleanup() {
        context.refreshAllObjects()
    }
}
