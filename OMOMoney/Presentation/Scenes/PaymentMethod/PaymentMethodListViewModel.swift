import CoreData
import Foundation

/// ViewModel for PaymentMethod list functionality
/// Handles paymentMethod list display and management
@MainActor
class PaymentMethodListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let paymentMethodService: any PaymentMethodServiceProtocol
    
    // MARK: - Initialization
    init(paymentMethodService: any PaymentMethodServiceProtocol) {
        self.paymentMethodService = paymentMethodService
    }
    
    // MARK: - Public Methods
    
    /// Load paymentMethods for a specific group
    func loadPaymentMethods(for group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            paymentMethods = try await paymentMethodService.getPaymentMethods(for: group)
        } catch {
            errorMessage = "Error loading paymentMethods: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load only active paymentMethods for a specific group
    func loadActivePaymentMethods(for group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            paymentMethods = try await paymentMethodService.getActivePaymentMethods(for: group)
        } catch {
            errorMessage = "Error loading active paymentMethods: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load paymentMethods by type for a specific group
    func loadPaymentMethods(for group: Group, type: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            paymentMethods = try await paymentMethodService.getPaymentMethods(for: group, type: type)
        } catch {
            errorMessage = "Error loading paymentMethods by type: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Create a new paymentMethod
    func createPaymentMethod(name: String, type: String, isActive: Bool = true, group: Group) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let groupId = group.id else {
                errorMessage = "Invalid group ID"
                isLoading = false
                return false
            }
            
            let newPaymentMethod = try await paymentMethodService.createPaymentMethod(
                name: name,
                type: type,
                isActive: isActive,
                groupId: groupId
            )
            paymentMethods.append(newPaymentMethod)
            paymentMethods.sort { ($0.name ?? "") < ($1.name ?? "") }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating paymentMethod: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Update an existing paymentMethod
    func updatePaymentMethod(_ paymentMethod: PaymentMethod, name: String? = nil, type: String? = nil, isActive: Bool? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await paymentMethodService.updatePaymentMethod(paymentMethod, name: name, type: type, isActive: isActive)
            
            // Update local array
            if let index = paymentMethods.firstIndex(where: { $0.id == paymentMethod.id }) {
                if let name = name {
                    paymentMethods[index].name = name
                }
                if let type = type {
                    paymentMethods[index].type = type
                }
                if let isActive = isActive {
                    paymentMethods[index].isActive = isActive
                }
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating paymentMethod: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete a paymentMethod
    func deletePaymentMethod(_ paymentMethod: PaymentMethod) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await paymentMethodService.deletePaymentMethod(paymentMethod)
            paymentMethods.removeAll { $0.id == paymentMethod.id }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting paymentMethod: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Toggle active status of a paymentMethod
    func toggleActiveStatus(_ paymentMethod: PaymentMethod) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await paymentMethodService.toggleActiveStatus(paymentMethod)
            
            // Update local array
            if let index = paymentMethods.firstIndex(where: { $0.id == paymentMethod.id }) {
                paymentMethods[index].isActive.toggle()
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Error toggling paymentMethod status: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Get paymentMethods count for a specific group
    func getPaymentMethodsCount(for group: Group) async -> Int {
        do {
            return try await paymentMethodService.getPaymentMethodsCount(for: group)
        } catch {
            errorMessage = "Error getting paymentMethods count: \(error.localizedDescription)"
            return 0
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    
    /// Get active paymentMethods only
    var activePaymentMethods: [PaymentMethod] {
        return paymentMethods.filter { $0.isActive }
    }
    
    /// Get inactive paymentMethods only
    var inactivePaymentMethods: [PaymentMethod] {
        return paymentMethods.filter { !$0.isActive }
    }
    
    /// Get paymentMethods grouped by type
    var paymentMethodsByType: [String: [PaymentMethod]] {
        return Dictionary(grouping: paymentMethods) { $0.type ?? "unknown" }
    }
}
