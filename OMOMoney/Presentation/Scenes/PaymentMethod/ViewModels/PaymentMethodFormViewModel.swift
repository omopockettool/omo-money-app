import Foundation

@MainActor @Observable final class PaymentMethodFormViewModel {
    var isLoading = false
    var errorMessage: String?

    private let createPaymentMethodUseCase: CreatePaymentMethodUseCase
    private let updatePaymentMethodUseCase: UpdatePaymentMethodUseCase

    init(createPaymentMethodUseCase: CreatePaymentMethodUseCase,
         updatePaymentMethodUseCase: UpdatePaymentMethodUseCase) {
        self.createPaymentMethodUseCase = createPaymentMethodUseCase
        self.updatePaymentMethodUseCase = updatePaymentMethodUseCase
    }

    convenience init() {
        let c = AppDIContainer.shared
        self.init(
            createPaymentMethodUseCase: c.makeCreatePaymentMethodUseCase(),
            updatePaymentMethodUseCase: c.makeUpdatePaymentMethodUseCase()
        )
    }

    func save(name: String, type: String, icon: String, groupId: UUID, methodToEdit: SDPaymentMethod?) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let pm = methodToEdit {
                pm.name = name
                pm.type = type
                pm.icon = icon
                try await updatePaymentMethodUseCase.execute(pm)
            } else {
                _ = try await createPaymentMethodUseCase.execute(
                    name: name,
                    type: type,
                    icon: icon,
                    color: "#6C63FF",
                    isActive: true,
                    groupId: groupId
                )
            }
            return true
        } catch {
            errorMessage = "Error al guardar método de pago: \(error.localizedDescription)"
            return false
        }
    }
}
