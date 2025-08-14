import Foundation
import CoreData

/// Service class for Item entity operations
/// Handles all CRUD operations for Item with proper threading
class ItemService: CoreDataService, ItemServiceProtocol {
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - Item CRUD Operations
    
    /// Fetch all items
    func fetchItems() async throws -> [Item] {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: true)]
        return try await fetch(request)
    }
    
    /// Fetch item by ID
    func fetchItem(by id: UUID) async throws -> Item? {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Create a new item
    func createItem(description: String?, amount: NSDecimalNumber, quantity: Int32, entry: Entry) async throws -> Item {
        try await context.perform {
            let item = Item(context: self.context)
            item.id = UUID()
            item.itemDescription = description
            item.amount = amount
            item.quantity = quantity
            item.entry = entry
            item.createdAt = Date()
            
            try self.context.save()
            return item
        }
    }
    
    /// Update an existing item
    func updateItem(_ item: Item, description: String?, amount: NSDecimalNumber?, quantity: Int32?) async throws {
        try await context.perform {
            if let description = description {
                item.itemDescription = description
            }
            if let amount = amount {
                item.amount = amount
            }
            if let quantity = quantity {
                item.quantity = quantity
            }
            // Item doesn't have updatedAt, using createdAt instead
            
            try self.context.save()
        }
    }
    
    /// Delete an item
    func deleteItem(_ item: Item) async throws {
        await delete(item)
        try await save()
    }
    
    /// Get items for a specific entry
    func getItems(for entry: Entry) async throws -> [Item] {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "entry == %@", entry)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: true)]
        return try await fetch(request)
    }
    
    /// Get items for a specific group
    func getItems(for group: Group) async throws -> [Item] {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "entry.group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: true)]
        return try await fetch(request)
    }
    
    /// Calculate total amount for a specific entry
    func calculateTotalAmount(for entry: Entry) async throws -> NSDecimalNumber {
        let items = try await getItems(for: entry)
        return items.reduce(NSDecimalNumber.zero) { total, item in
            total.adding(item.amount ?? NSDecimalNumber.zero)
        }
    }
    
    /// Calculate total amount for a specific group
    func calculateTotalAmount(for group: Group) async throws -> NSDecimalNumber {
        let items = try await getItems(for: group)
        return items.reduce(NSDecimalNumber.zero) { total, item in
            total.adding(item.amount ?? NSDecimalNumber.zero)
        }
    }
    
    /// Get items count
    func getItemsCount() async throws -> Int {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        return try await count(request)
    }
}
