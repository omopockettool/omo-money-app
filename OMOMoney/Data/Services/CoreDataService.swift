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
            print("💾 [CoreDataService] save() ejecutándose")
            print("💾 [CoreDataService] HasChanges: \(self.context.hasChanges)")
            
            if self.context.hasChanges {
                let inserted = self.context.insertedObjects.count
                let updated = self.context.updatedObjects.count
                let deleted = self.context.deletedObjects.count
                print("💾 [CoreDataService] Cambios a guardar - Inserted: \(inserted), Updated: \(updated), Deleted: \(deleted)")
                
                // Mostrar objetos eliminados
                for obj in self.context.deletedObjects {
                    print("💾 [CoreDataService] Guardando eliminación de: \(type(of: obj)) - ObjectID: \(obj.objectID)")
                }
            }
            
            try self.context.save()
            print("💾 [CoreDataService] context.save() completado ✅")
        }
    }
    
    /// Generic delete method with proper threading
    func delete(_ object: NSManagedObject) async {
        await context.perform {
            print("💀 [CoreDataService] delete() ejecutándose en context.perform")
            print("💀 [CoreDataService] Object tipo: \(type(of: object))")
            print("💀 [CoreDataService] Object ObjectID: \(object.objectID)")
            print("💀 [CoreDataService] Context: \(self.context)")
            print("💀 [CoreDataService] Objetos registrados ANTES: \(self.context.registeredObjects.count)")
            
            self.context.delete(object)
            
            print("💀 [CoreDataService] context.delete() ejecutado")
            print("💀 [CoreDataService] Objetos registrados DESPUÉS: \(self.context.registeredObjects.count)")
            print("💀 [CoreDataService] HasChanges: \(self.context.hasChanges)")
            
            if self.context.hasChanges {
                let inserted = self.context.insertedObjects.count
                let updated = self.context.updatedObjects.count
                let deleted = self.context.deletedObjects.count
                print("💀 [CoreDataService] Cambios pendientes - Inserted: \(inserted), Updated: \(updated), Deleted: \(deleted)")
                
                // Mostrar qué se va a eliminar
                for obj in self.context.deletedObjects {
                    print("💀 [CoreDataService] Objeto marcado para eliminar: \(type(of: obj)) - ObjectID: \(obj.objectID)")
                }
            }
        }
    }
    
    /// Generic count method with proper threading
    func count<T: NSManagedObject>(_ request: NSFetchRequest<T>) async throws -> Int {
        try await context.perform {
            try self.context.count(for: request)
        }
    }
    
}
