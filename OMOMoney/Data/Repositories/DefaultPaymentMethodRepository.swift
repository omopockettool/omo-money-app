import Foundation
import SwiftData

final class DefaultPaymentMethodRepository: PaymentMethodRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchPaymentMethods() async throws -> [PaymentMethodDomain] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<SDPaymentMethod>()
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func fetchPaymentMethod(id: UUID) async throws -> PaymentMethodDomain? {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDPaymentMethod>(predicate: #Predicate { $0.id == targetId })
            return try context.fetch(descriptor).first?.toDomain()
        }
    }

    func fetchPaymentMethods(forGroupId groupId: UUID) async throws -> [PaymentMethodDomain] {
        try await MainActor.run {
            let targetGroupId = groupId
            let descriptor = FetchDescriptor<SDPaymentMethod>(
                predicate: #Predicate { $0.group?.id == targetGroupId },
                sortBy: [SortDescriptor(\.name)]
            )
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func fetchActivePaymentMethods() async throws -> [PaymentMethodDomain] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<SDPaymentMethod>(
                predicate: #Predicate { $0.isActive }
            )
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func createPaymentMethod(
        name: String,
        type: String,
        icon: String,
        color: String,
        isActive: Bool,
        isDefault: Bool,
        groupId: UUID?
    ) async throws -> PaymentMethodDomain {
        try await MainActor.run {
            let pm = SDPaymentMethod(
                name: name,
                type: type,
                icon: icon,
                color: color,
                isActive: isActive,
                isDefault: isDefault
            )
            if let groupId {
                let targetId = groupId
                let descriptor = FetchDescriptor<SDGroup>(predicate: #Predicate { $0.id == targetId })
                pm.group = try context.fetch(descriptor).first
            }
            context.insert(pm)
            try context.save()
            return pm.toDomain()
        }
    }

    func updatePaymentMethod(_ paymentMethod: PaymentMethodDomain) async throws {
        try await MainActor.run {
            let targetId = paymentMethod.id
            let descriptor = FetchDescriptor<SDPaymentMethod>(predicate: #Predicate { $0.id == targetId })
            guard let existing = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            existing.name = paymentMethod.name
            existing.type = paymentMethod.type
            existing.icon = paymentMethod.icon
            existing.color = paymentMethod.color
            existing.isActive = paymentMethod.isActive
            existing.lastModifiedAt = Date()
            try context.save()
        }
    }

    func deletePaymentMethod(id: UUID) async throws {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDPaymentMethod>(predicate: #Predicate { $0.id == targetId })
            guard let pm = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            context.delete(pm)
            try context.save()
        }
    }
}

// MARK: - Domain mapping
private extension SDPaymentMethod {
    func toDomain() -> PaymentMethodDomain {
        PaymentMethodDomain(
            id: id,
            name: name,
            type: type,
            icon: icon,
            color: color,
            isActive: isActive,
            isDefault: isDefault,
            groupId: group?.id,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
