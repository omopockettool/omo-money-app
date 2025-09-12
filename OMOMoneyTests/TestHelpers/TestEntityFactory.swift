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
    
    // MARK: - ItemLists Factory Methods
    
    /// Create a test itemLists
    func createItemLists(description: String = "Test ItemLists", date: Date = Date(), category: OMOMoney.Category? = nil, group: Group? = nil) -> ItemLists {
        let itemLists = ItemLists(context: context)
        itemLists.id = UUID()
        itemLists.itemListDescription = description
        itemLists.date = date
        itemLists.category = category
        itemLists.group = group
        itemLists.createdAt = Date()
        itemLists.lastModifiedAt = Date()
        return itemLists
    }
    
    /// Create multiple test itemLists
    func createItemLists(count: Int, prefix: String = "ItemLists", category: OMOMoney.Category? = nil, group: Group? = nil) -> [ItemLists] {
        return (0..<count).map { index in
            createItemLists(
                description: "\(prefix) \(index + 1)",
                date: Date().addingTimeInterval(TimeInterval(-index * 86400)), // Each itemLists one day apart
                category: category,
                group: group
            )
        }
    }
    
    // MARK: - Item Factory Methods
    
    /// Create a test item
    func createItem(description: String = "Test Item", amount: NSDecimalNumber = NSDecimalNumber(value: 10.0), quantity: Int32 = 1, itemLists: ItemLists? = nil) -> Item {
        let item = Item(context: context)
        item.id = UUID()
        item.itemDescription = description
        item.amount = amount
        item.quantity = quantity
        item.itemList = itemLists
        item.createdAt = Date()
        item.lastModifiedAt = Date()
        return item
    }
    
    /// Create multiple test items
    func createItems(count: Int, prefix: String = "Item", itemLists: ItemLists? = nil) -> [Item] {
        return (0..<count).map { index in
            createItem(
                description: "\(prefix) \(index + 1)",
                amount: NSDecimalNumber(value: Double(index + 1) * 5.0),
                quantity: Int32(index + 1),
                itemLists: itemLists
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
    
    /// Create a complete test scenario with users, groups, categories, itemLists, and items
    func createCompleteTestScenario() -> (users: [User], groups: [Group], categories: [OMOMoney.Category], itemLists: [ItemLists], items: [Item], userGroups: [UserGroup]) {
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
        
        // Create itemLists for each group
        var allItemLists: [ItemLists] = []
        for group in groups {
            let groupItemLists = createItemLists(count: 5, group: group)
            allItemLists.append(contentsOf: groupItemLists)
        }
        
        // Create items for each itemLists
        var allItems: [Item] = []
        for itemLists in allItemLists {
            let itemListsItems = createItems(count: 2, itemLists: itemLists)
            allItems.append(contentsOf: itemListsItems)
        }
        
        // Create user group relationships
        let userGroups = createUserGroups(users: users, groups: groups)
        
        return (users, groups, allCategories, allItemLists, allItems, userGroups)
    }
    
    // MARK: - Cleanup
    
    /// Clean up all test entities
    func cleanup() {
        context.refreshAllObjects()
    }
}
