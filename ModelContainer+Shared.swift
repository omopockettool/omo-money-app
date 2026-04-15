import Foundation
import SwiftData

extension ModelContainer {
    
    @MainActor
    static var shared: ModelContainer = {
        let schema = Schema([
            SDUser.self,
            SDGroup.self,
            SDUserGroup.self,
            SDCategory.self,
            SDPaymentMethod.self,
            SDItemList.self,
            SDItem.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            print("✅ ModelContainer initialized successfully")
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()
    
    @MainActor
    static var preview: ModelContainer = {
        let schema = Schema([
            SDUser.self,
            SDGroup.self,
            SDUserGroup.self,
            SDCategory.self,
            SDPaymentMethod.self,
            SDItemList.self,
            SDItem.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = container.mainContext
            
            let user = SDUser.mock(name: "Preview User", email: "preview@omomoney.app")
            context.insert(user)
            
            let group = SDGroup.mock(name: "Preview Group", currency: "USD")
            context.insert(group)
            
            let userGroup = SDUserGroup.mock(role: "owner")
            userGroup.user = user
            userGroup.group = group
            context.insert(userGroup)
            
            let category = SDCategory.mock(
                name: "Groceries",
                color: "#FF6B6B",
                icon: "cart.fill",
                limit: 500.0
            )
            category.group = group
            context.insert(category)
            
            let paymentMethod = SDPaymentMethod.mock(
                name: "Credit Card",
                type: "card",
                icon: "creditcard.fill",
                color: "#2196F3"
            )
            paymentMethod.group = group
            context.insert(paymentMethod)
            
            let itemList = SDItemList.mock(
                itemListDescription: "Weekly Shopping",
                date: Date(),
                category: category,
                paymentMethod: paymentMethod,
                group: group
            )
            context.insert(itemList)
            
            let item1 = SDItem.mock(
                itemDescription: "Milk",
                amount: 3.99,
                quantity: 2,
                isPaid: true
            )
            item1.itemList = itemList
            context.insert(item1)
            
            let item2 = SDItem.mock(
                itemDescription: "Bread",
                amount: 2.50,
                quantity: 1,
                isPaid: false
            )
            item2.itemList = itemList
            context.insert(item2)
            
            try context.save()
            
            print("✅ Preview ModelContainer initialized with sample data")
            
            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }()
    
    @MainActor
    static func test() -> ModelContainer {
        let schema = Schema([
            SDUser.self,
            SDGroup.self,
            SDUserGroup.self,
            SDCategory.self,
            SDPaymentMethod.self,
            SDItemList.self,
            SDItem.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            print("✅ Test ModelContainer initialized (empty)")
            return container
        } catch {
            fatalError("Failed to create test ModelContainer: \(error)")
        }
    }
}

extension ModelContext {
    
    func safeSave() throws {
        guard hasChanges else { return }
        
        do {
            try save()
            print("✅ ModelContext saved successfully")
        } catch {
            print("❌ ModelContext save failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func safeRollback() {
        rollback()
        print("⚠️ ModelContext rolled back")
    }
    
    func deleteWithCascade<T: PersistentModel>(_ model: T) {
        delete(model)
        print("🗑️ Deleted \(type(of: model))")
    }
}

extension ModelContainer {
    
    @MainActor
    func isEmpty() -> Bool {
        let context = mainContext
        
        do {
            let userCount = try context.fetchCount(FetchDescriptor<SDUser>())
            return userCount == 0
        } catch {
            print("❌ Error checking if container is empty: \(error)")
            return true
        }
    }
    
    @MainActor
    func getStatistics() -> ContainerStatistics {
        let context = mainContext
        
        do {
            let users = try context.fetchCount(FetchDescriptor<SDUser>())
            let groups = try context.fetchCount(FetchDescriptor<SDGroup>())
            let categories = try context.fetchCount(FetchDescriptor<SDCategory>())
            let paymentMethods = try context.fetchCount(FetchDescriptor<SDPaymentMethod>())
            let itemLists = try context.fetchCount(FetchDescriptor<SDItemList>())
            let items = try context.fetchCount(FetchDescriptor<SDItem>())
            
            return ContainerStatistics(
                users: users,
                groups: groups,
                categories: categories,
                paymentMethods: paymentMethods,
                itemLists: itemLists,
                items: items
            )
        } catch {
            print("❌ Error getting statistics: \(error)")
            return ContainerStatistics()
        }
    }
}

struct ContainerStatistics {
    let users: Int
    let groups: Int
    let categories: Int
    let paymentMethods: Int
    let itemLists: Int
    let items: Int
    
    init(
        users: Int = 0,
        groups: Int = 0,
        categories: Int = 0,
        paymentMethods: Int = 0,
        itemLists: Int = 0,
        items: Int = 0
    ) {
        self.users = users
        self.groups = groups
        self.categories = categories
        self.paymentMethods = paymentMethods
        self.itemLists = itemLists
        self.items = items
    }
    
    var description: String {
        """
        📊 Container Statistics:
        - Users: \(users)
        - Groups: \(groups)
        - Categories: \(categories)
        - Payment Methods: \(paymentMethods)
        - Item Lists: \(itemLists)
        - Items: \(items)
        """
    }
}
