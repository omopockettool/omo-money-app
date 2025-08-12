import Foundation
import CoreData

/// Base service class for Core Data operations
/// Provides common CRUD functionality and ensures proper threading
@MainActor
class CoreDataService: ObservableObject {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Generic CRUD Operations
    
    /// Generic fetch method with proper threading
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> [T] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let results = try self.context.fetch(request)
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Generic save method with proper threading
    func save() async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Generic delete method with proper threading
    func delete(_ object: NSManagedObject) async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                self.context.delete(object)
                continuation.resume()
            }
        }
    }
    
    /// Generic count method with proper threading
    func count<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let count = try self.context.count(for: request)
                    continuation.resume(returning: count)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
