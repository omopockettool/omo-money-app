import Foundation
import SwiftUI

@MainActor @Observable final class PaymentMethodListViewModel {

    var paymentMethods: [SDPaymentMethod] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false

    private let fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase
    private let deletePaymentMethodUseCase: DeletePaymentMethodUseCase

    init(fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase,
         deletePaymentMethodUseCase: DeletePaymentMethodUseCase) {
        self.fetchPaymentMethodsUseCase = fetchPaymentMethodsUseCase
        self.deletePaymentMethodUseCase = deletePaymentMethodUseCase
    }

    convenience init() {
        let c = AppDIContainer.shared
        self.init(
            fetchPaymentMethodsUseCase: c.makeFetchPaymentMethodsUseCase(),
            deletePaymentMethodUseCase: c.makeDeletePaymentMethodUseCase()
        )
    }

    func loadPaymentMethods(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil
        showError = false
        do {
            paymentMethods = try await fetchPaymentMethodsUseCase.execute(forGroupId: groupId)
        } catch {
            errorMessage = "Error al cargar métodos de pago: \(error.localizedDescription)"
            showError = true
        }
        isLoading = false
    }

    func deletePaymentMethod(_ pm: SDPaymentMethod) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            paymentMethods.removeAll { $0.id == pm.id }
        }
        Task {
            do {
                try await deletePaymentMethodUseCase.execute(id: pm.id)
            } catch {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                    paymentMethods.append(pm)
                }
                errorMessage = "Error al eliminar método de pago: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}
