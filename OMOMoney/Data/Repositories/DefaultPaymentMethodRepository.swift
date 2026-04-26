import Foundation
import SwiftData

@MainActor
final class DefaultPaymentMethodRepository: PaymentMethodRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchPaymentMethods(forGroupId groupId: UUID) async throws -> [SDPaymentMethod] {
        let targetGroupId = groupId
        let descriptor = FetchDescriptor<SDPaymentMethod>(
            predicate: #Predicate { $0.group?.id == targetGroupId },
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func createPaymentMethod(
        name: String,
        type: String,
        icon: String,
        color: String,
        isActive: Bool,
        groupId: UUID?
    ) async throws -> SDPaymentMethod {
        let pm = SDPaymentMethod(name: name, type: type, icon: icon, color: color, isActive: isActive)
        if let groupId {
            let targetId = groupId
            let descriptor = FetchDescriptor<SDGroup>(predicate: #Predicate { $0.id == targetId })
            pm.group = try context.fetch(descriptor).first
        }
        context.insert(pm)
        try context.save()
        return pm
    }

    func updatePaymentMethod(_ paymentMethod: SDPaymentMethod) async throws {
        paymentMethod.lastModifiedAt = Date()
        try context.save()
    }

    func deletePaymentMethod(id: UUID) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<SDPaymentMethod>(predicate: #Predicate { $0.id == targetId })
        guard let pm = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(pm)
        try context.save()
    }
}
