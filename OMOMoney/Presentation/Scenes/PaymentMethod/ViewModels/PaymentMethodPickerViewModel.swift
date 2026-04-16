import Foundation

@MainActor

@Observable
class PaymentMethodPickerViewModel {

    // MARK: - Published Properties
    var availablePaymentMethods: [SDPaymentMethod] = []
    var selectedPaymentMethod: SDPaymentMethod?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Private Properties
    private let fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase
    private var currentGroupId: UUID?

    // MARK: - Initialization
    init(fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase) {
        self.fetchPaymentMethodsUseCase = fetchPaymentMethodsUseCase
    }

    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(fetchPaymentMethodsUseCase: appContainer.makeFetchPaymentMethodsUseCase())
    }

    // MARK: - Public Methods

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

    func selectPaymentMethod(_ paymentMethod: SDPaymentMethod) {
        selectedPaymentMethod = paymentMethod
    }

    func clearSelection() {
        selectedPaymentMethod = nil
    }

    func getPaymentMethod(by id: UUID) -> SDPaymentMethod? {
        return availablePaymentMethods.first { $0.id == id }
    }

    func setSelectedPaymentMethod(by id: UUID?) {
        if let id = id {
            selectedPaymentMethod = getPaymentMethod(by: id)
        } else {
            selectedPaymentMethod = nil
        }
    }

    func isPaymentMethodSelected(_ paymentMethod: SDPaymentMethod) -> Bool {
        return selectedPaymentMethod?.id == paymentMethod.id
    }

    var selectedPaymentMethodDisplayName: String {
        return selectedPaymentMethod?.name ?? "No payment method selected"
    }

    var hasAvailablePaymentMethods: Bool {
        return !availablePaymentMethods.isEmpty
    }

    var paymentMethodsByType: [String: [SDPaymentMethod]] {
        return Dictionary(grouping: availablePaymentMethods) { $0.type }
    }

    var availableTypes: [String] {
        return Array(Set(availablePaymentMethods.map { $0.type })).sorted()
    }

    func clearError() {
        errorMessage = nil
    }

    func refreshPaymentMethods() async {
        guard let currentGroupId = currentGroupId else { return }
        await loadAvailablePaymentMethods(forGroupId: currentGroupId)
    }

    var isValidSelection: Bool {
        return selectedPaymentMethod != nil
    }

    var validationErrorMessage: String? {
        if !isValidSelection {
            return "Please select a payment method"
        }
        return nil
    }
}
