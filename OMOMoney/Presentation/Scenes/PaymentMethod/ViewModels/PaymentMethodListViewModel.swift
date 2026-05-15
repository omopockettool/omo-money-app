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

    func deletePaymentMethod(paymentMethodId: UUID) async {
        guard let pm = paymentMethods.first(where: { $0.id == paymentMethodId }) else { return }
        withAnimation { paymentMethods.removeAll { $0.id == paymentMethodId } }
        do {
            try await deletePaymentMethodUseCase.execute(id: paymentMethodId)
        } catch {
            withAnimation { paymentMethods.append(pm) }
            errorMessage = "Error al eliminar método de pago: \(error.localizedDescription)"
            showError = true
        }
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}
