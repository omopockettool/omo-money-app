import CoreData
import Foundation

/// Base service class for Core Data operations
/// Provides common CRUD functionality and ensures proper threading
class CoreDataService {
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
    
    // MARK: - Batch Operations
    
    /// Perform batch delete operation for better performance with large datasets
    func batchDelete<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) async throws -> NSBatchDeleteResult {
        try await context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
            fetchRequest.predicate = predicate
            
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            
            guard let result = try self.context.execute(batchDeleteRequest) as? NSBatchDeleteResult else {
                throw CoreDataError.batchOperationFailed
            }
            
            // Merge changes to view context
            if let objectIDs = result.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
            }
            
            return result
        }
    }
    
    /// Perform batch update operation for better performance
    func batchUpdate<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate?, propertiesToUpdate: [String: Any]) async throws -> NSBatchUpdateResult {
        try await context.perform {
            let batchUpdateRequest = NSBatchUpdateRequest(entityName: String(describing: entityType))
            batchUpdateRequest.predicate = predicate
            batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
            batchUpdateRequest.resultType = .updatedObjectIDsResultType
            
            guard let result = try self.context.execute(batchUpdateRequest) as? NSBatchUpdateResult else {
                throw CoreDataError.batchOperationFailed
            }
            
            // Merge changes to view context
            if let objectIDs = result.result as? [NSManagedObjectID] {
                let changes = [NSUpdatedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
            }
            
            return result
        }
    }
    
    /// Bulk insert operation for creating multiple objects efficiently
    func bulkInsert<T: NSManagedObject>(_ entityType: T.Type, objects: [[String: Any]]) async throws {
        try await context.perform {
            let batchInsertRequest = NSBatchInsertRequest(entityName: String(describing: entityType), objects: objects)
            try self.context.execute(batchInsertRequest)
        }
    }
}

// MARK: - Core Data Errors

enum CoreDataError: Error, LocalizedError {
    case batchOperationFailed
    case invalidObjectID
    case contextSaveFailed
    
    var errorDescription: String? {
        switch self {
        case .batchOperationFailed:
            return "Batch operation failed to execute"
        case .invalidObjectID:
            return "Invalid managed object ID"
        case .contextSaveFailed:
            return "Failed to save managed object context"
        }
    }
}
