import CoreData
import Foundation

/// Protocol for PaymentMethod service operations
/// Enables dependency injection and testing
protocol PaymentMethodServiceProtocol {
    
    // MARK: - PaymentMethod CRUD Operations
    
    /// Fetch paymentMethod by ID
    func fetchPaymentMethod(by id: UUID) async throws -> PaymentMethod?
    
    /// Create a new paymentMethod
    func createPaymentMethod(name: String, type: String, isActive: Bool, groupId: UUID) async throws -> PaymentMethod
    
    /// Update an existing paymentMethod
    func updatePaymentMethod(_ paymentMethod: PaymentMethod, name: String?, type: String?, isActive: Bool?) async throws
    
    /// Delete a paymentMethod
    func deletePaymentMethod(_ paymentMethod: PaymentMethod) async throws
    
    /// Get paymentMethods for a specific group
    func getPaymentMethods(for group: Group) async throws -> [PaymentMethod]
    
    /// Get active paymentMethods for a specific group
    func getActivePaymentMethods(for group: Group) async throws -> [PaymentMethod]
    
    /// Get paymentMethods count for a specific group
    func getPaymentMethodsCount(for group: Group) async throws -> Int
    
    /// Toggle paymentMethod active status
    func toggleActiveStatus(_ paymentMethod: PaymentMethod) async throws
    
    /// Get paymentMethods by type
    func getPaymentMethods(for group: Group, type: String) async throws -> [PaymentMethod]
}
