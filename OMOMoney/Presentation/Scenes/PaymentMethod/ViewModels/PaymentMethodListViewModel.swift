import Foundation

@MainActor

@Observable
class PaymentMethodListViewModel {

    // MARK: - Published Properties
    var paymentMethods: [SDPaymentMethod] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Use Cases
    private let fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase
    private let createPaymentMethodUseCase: CreatePaymentMethodUseCase
    private let updatePaymentMethodUseCase: UpdatePaymentMethodUseCase
    private let deletePaymentMethodUseCase: DeletePaymentMethodUseCase

    // MARK: - Initialization
    init(
        fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase,
        createPaymentMethodUseCase: CreatePaymentMethodUseCase,
        updatePaymentMethodUseCase: UpdatePaymentMethodUseCase,
        deletePaymentMethodUseCase: DeletePaymentMethodUseCase
    ) {
        self.fetchPaymentMethodsUseCase = fetchPaymentMethodsUseCase
        self.createPaymentMethodUseCase = createPaymentMethodUseCase
        self.updatePaymentMethodUseCase = updatePaymentMethodUseCase
        self.deletePaymentMethodUseCase = deletePaymentMethodUseCase
    }

    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(
            fetchPaymentMethodsUseCase: appContainer.makeFetchPaymentMethodsUseCase(),
            createPaymentMethodUseCase: appContainer.makeCreatePaymentMethodUseCase(),
            updatePaymentMethodUseCase: appContainer.makeUpdatePaymentMethodUseCase(),
            deletePaymentMethodUseCase: appContainer.makeDeletePaymentMethodUseCase()
        )
    }

    // MARK: - Public Methods

    func loadPaymentMethods(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            paymentMethods = try await fetchPaymentMethodsUseCase.execute(forGroupId: groupId)
        } catch {
            errorMessage = "Error loading paymentMethods: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadActivePaymentMethods(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            paymentMethods = try await fetchPaymentMethodsUseCase.executeActive(forGroupId: groupId)
        } catch {
            errorMessage = "Error loading active paymentMethods: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadPaymentMethods(forGroupId groupId: UUID, type: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let allMethods = try await fetchPaymentMethodsUseCase.execute(forGroupId: groupId)
            paymentMethods = allMethods.filter { $0.type == type }
        } catch {
            errorMessage = "Error loading paymentMethods by type: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func createPaymentMethod(name: String, type: String, icon: String = "creditcard.fill", isActive: Bool = true, groupId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newPaymentMethod = try await createPaymentMethodUseCase.execute(
                name: name,
                type: type,
                icon: icon,
                color: "#6C63FF",
                isActive: isActive,
                groupId: groupId
            )
            paymentMethods.append(newPaymentMethod)
            paymentMethods.sort { $0.name < $1.name }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating paymentMethod: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func updatePaymentMethod(_ existing: SDPaymentMethod, name: String, type: String, icon: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            existing.name = name
            existing.type = type
            existing.icon = icon
            try await updatePaymentMethodUseCase.execute(existing)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating paymentMethod: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func deletePaymentMethod(paymentMethodId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await deletePaymentMethodUseCase.execute(id: paymentMethodId)
            paymentMethods.removeAll { $0.id == paymentMethodId }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting paymentMethod: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func toggleActiveStatus(paymentMethodId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            guard let currentMethod = paymentMethods.first(where: { $0.id == paymentMethodId }) else {
                errorMessage = "Payment method not found"
                isLoading = false
                return false
            }

            currentMethod.isActive.toggle()
            try await updatePaymentMethodUseCase.execute(currentMethod)

            isLoading = false
            return true
        } catch {
            errorMessage = "Error toggling paymentMethod status: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func getPaymentMethodsCount(forGroupId groupId: UUID) async -> Int {
        return paymentMethods.count
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Computed Properties

    var activePaymentMethods: [SDPaymentMethod] {
        return paymentMethods.filter { $0.isActive }
    }

    var inactivePaymentMethods: [SDPaymentMethod] {
        return paymentMethods.filter { !$0.isActive }
    }

    var paymentMethodsByType: [String: [SDPaymentMethod]] {
        return Dictionary(grouping: paymentMethods) { $0.type }
    }
}
