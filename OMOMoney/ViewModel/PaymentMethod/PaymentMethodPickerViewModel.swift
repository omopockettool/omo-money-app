import CoreData
import Foundation

/// ViewModel for PaymentMethod picker functionality
/// Handles payment method selection in forms and pickers
@MainActor
class PaymentMethodPickerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var availablePaymentMethods: [PaymentMethod] = []
    @Published var selectedPaymentMethod: PaymentMethod?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let paymentMethodService: any PaymentMethodServiceProtocol
    private var currentGroup: Group?
    
    // MARK: - Initialization
    init(paymentMethodService: any PaymentMethodServiceProtocol) {
        self.paymentMethodService = paymentMethodService
    }
    
    // MARK: - Public Methods
    
    /// Load available payment methods for a specific group
    func loadAvailablePaymentMethods(for group: Group) async {
        self.currentGroup = group
        isLoading = true
        errorMessage = nil
        
        do {
            availablePaymentMethods = try await paymentMethodService.getActivePaymentMethods(for: group)
        } catch {
            errorMessage = "Error loading payment methods: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load available payment methods by type for a specific group
    func loadAvailablePaymentMethods(for group: Group, type: String) async {
        self.currentGroup = group
        isLoading = true
        errorMessage = nil
        
        do {
            let allPaymentMethods = try await paymentMethodService.getPaymentMethods(for: group, type: type)
            availablePaymentMethods = allPaymentMethods.filter { $0.isActive }
        } catch {
            errorMessage = "Error loading payment methods: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Select a payment method
    func selectPaymentMethod(_ paymentMethod: PaymentMethod) {
        selectedPaymentMethod = paymentMethod
    }
    
    /// Clear the selected payment method
    func clearSelection() {
        selectedPaymentMethod = nil
    }
    
    /// Get payment method by ID
    func getPaymentMethod(by id: UUID) -> PaymentMethod? {
        return availablePaymentMethods.first { $0.id == id }
    }
    
    /// Set selected payment method by ID
    func setSelectedPaymentMethod(by id: UUID?) {
        if let id = id {
            selectedPaymentMethod = getPaymentMethod(by: id)
        } else {
            selectedPaymentMethod = nil
        }
    }
    
    /// Check if a payment method is selected
    func isPaymentMethodSelected(_ paymentMethod: PaymentMethod) -> Bool {
        return selectedPaymentMethod?.id == paymentMethod.id
    }
    
    /// Get the display name for selected payment method
    var selectedPaymentMethodDisplayName: String {
        return selectedPaymentMethod?.name ?? "No payment method selected"
    }
    
    /// Check if there are available payment methods
    var hasAvailablePaymentMethods: Bool {
        return !availablePaymentMethods.isEmpty
    }
    
    /// Get payment methods grouped by type
    var paymentMethodsByType: [String: [PaymentMethod]] {
        return Dictionary(grouping: availablePaymentMethods) { $0.type ?? "unknown" }
    }
    
    /// Get unique types available
    var availableTypes: [String] {
        return Array(Set(availablePaymentMethods.compactMap { $0.type })).sorted()
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Refresh payment methods for current group
    func refreshPaymentMethods() async {
        guard let currentGroup = currentGroup else { return }
        await loadAvailablePaymentMethods(for: currentGroup)
    }
    
    // MARK: - Validation
    
    /// Validate that a payment method is selected
    var isValidSelection: Bool {
        return selectedPaymentMethod != nil
    }
    
    /// Get validation error message
    var validationErrorMessage: String? {
        if !isValidSelection {
            return "Please select a payment method"
        }
        return nil
    }
}
