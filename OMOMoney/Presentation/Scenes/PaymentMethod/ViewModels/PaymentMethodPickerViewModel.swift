import Foundation

/// ViewModel for PaymentMethod picker functionality
/// Handles payment method selection in forms and pickers
/// ✅ CLEAN ARCHITECTURE: Uses Use Cases
@MainActor

@Observable
class PaymentMethodPickerViewModel {

    // MARK: - Published Properties
    var availablePaymentMethods: [PaymentMethodDomain] = []
    var selectedPaymentMethod: PaymentMethodDomain?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Private Properties
    private let fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase
    private var currentGroupId: UUID?

    // MARK: - Initialization
    init(fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase) {
        self.fetchPaymentMethodsUseCase = fetchPaymentMethodsUseCase
    }

    /// Convenience initializer using DI Container
    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(fetchPaymentMethodsUseCase: appContainer.makeFetchPaymentMethodsUseCase())
    }

    // MARK: - Public Methods

    /// Load available payment methods for a specific group
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func loadAvailablePaymentMethods(forGroupId groupId: UUID) async {
        self.currentGroupId = groupId
        isLoading = true
        errorMessage = nil

        do {
            availablePaymentMethods = try await fetchPaymentMethodsUseCase.executeActive(forGroupId: groupId)
        } catch {
            errorMessage = "Error loading payment methods: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Load available payment methods by type for a specific group
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case with client-side filtering
    func loadAvailablePaymentMethods(forGroupId groupId: UUID, type: String) async {
        self.currentGroupId = groupId
        isLoading = true
        errorMessage = nil

        do {
            let allPaymentMethods = try await fetchPaymentMethodsUseCase.execute(forGroupId: groupId)
            availablePaymentMethods = allPaymentMethods.filter { $0.isActive && $0.type == type }
        } catch {
            errorMessage = "Error loading payment methods: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Select a payment method
    func selectPaymentMethod(_ paymentMethod: PaymentMethodDomain) {
        selectedPaymentMethod = paymentMethod
    }

    /// Clear the selected payment method
    func clearSelection() {
        selectedPaymentMethod = nil
    }

    /// Get payment method by ID
    func getPaymentMethod(by id: UUID) -> PaymentMethodDomain? {
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
    func isPaymentMethodSelected(_ paymentMethod: PaymentMethodDomain) -> Bool {
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
    var paymentMethodsByType: [String: [PaymentMethodDomain]] {
        return Dictionary(grouping: availablePaymentMethods) { $0.type }
    }

    /// Get unique types available
    var availableTypes: [String] {
        return Array(Set(availablePaymentMethods.map { $0.type })).sorted()
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Refresh payment methods for current group
    func refreshPaymentMethods() async {
        guard let currentGroupId = currentGroupId else { return }
        await loadAvailablePaymentMethods(forGroupId: currentGroupId)
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
