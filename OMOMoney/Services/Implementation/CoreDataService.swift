import Foundation
import CoreData

/// Base service class for Core Data operations
/// Provides common CRUD functionality and ensures proper threading
class CoreDataService: ObservableObject {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Generic CRUD Operations
    
    /// Generic fetch method with proper threading
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T] {
        try await context.perform {
            try self.context.fetch(request)
        }
    }
    
    /// Generic save method with proper threading
    func save() async throws {
        try await context.perform {
            try self.context.save()
        }
    }
    
    /// Generic delete method with proper threading
    func delete(_ object: NSManagedObject) async {
        await context.perform {
            self.context.delete(object)
        }
    }
    
    /// Generic count method with proper threading
    func count<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> Int {
        try await context.perform {
            try self.context.count(for: request)
        }
    }
}
