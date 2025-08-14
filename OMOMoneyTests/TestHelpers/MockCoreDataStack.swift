import Foundation
import CoreData
@testable import OMOMoney

/// Mock Core Data stack for testing purposes
/// Provides an in-memory Core Data stack for unit tests
class MockCoreDataStack {
    
    // MARK: - Properties
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "OMOMoney")
        
        // Use in-memory store for testing
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Test Helpers
    
    /// Create a test context with automatic saving disabled
    func createTestContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
        context.automaticallyMergesChangesFromParent = false
        return context
    }
    
    /// Clear all data from the test store
    func clearAllData() {
        let context = viewContext
        let entities = persistentContainer.managedObjectModel.entities
        
        entities.forEach { entity in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Error clearing data for entity \(entity.name!): \(error)")
            }
        }
        
        try? context.save()
    }
    
    /// Save the test context
    func save() throws {
        try viewContext.save()
    }
    
    /// Reset the entire stack
    func reset() {
        clearAllData()
        viewContext.refreshAllObjects()
    }
}
