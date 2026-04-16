import Foundation
import SwiftData

final class DefaultGroupRepository: GroupRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchGroup(id: UUID) async throws -> SDGroup? {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDGroup>(predicate: #Predicate { $0.id == targetId })
            return try context.fetch(descriptor).first
        }
    }

    func createGroup(name: String, currency: String) async throws -> SDGroup {
        try await MainActor.run {
            let group = SDGroup(name: name, currency: currency)
            context.insert(group)

            let defaultPaymentMethods: [(String, String, String, String, Bool)] = [
                ("Efectivo",      "cash",          "banknote.fill",          "#4CAF50", true),
                ("Débito",        "card_debit",    "creditcard.fill",        "#2196F3", false),
                ("Crédito",       "card_credit",   "creditcard.fill",        "#9C27B0", false),
                ("Transferencia", "bank_transfer", "arrow.left.arrow.right", "#FF9800", false)
            ]
            for (pmName, pmType, pmIcon, pmColor, pmIsDefault) in defaultPaymentMethods {
                let pm = SDPaymentMethod(name: pmName, type: pmType, icon: pmIcon, color: pmColor, isActive: true, isDefault: pmIsDefault)
                pm.group = group
                context.insert(pm)
            }

            let defaultCategories: [(String, String, String, Bool)] = [
                ("Alimentación", "#FF6B6B", "cart.fill",            false),
                ("Movilidad",    "#4ECDC4", "car.fill",             false),
                ("Hogar",        "#45B7D1", "house.fill",           false),
                ("Ocio",         "#96CEB4", "theatermasks.fill",    false),
                ("Salud",        "#FFEAA7", "heart.fill",           false),
                ("Otros",        "#BDC3C7", "ellipsis.circle.fill", true)
            ]
            for (catName, catColor, catIcon, catIsDefault) in defaultCategories {
                let cat = SDCategory(name: catName, color: catColor, icon: catIcon, isDefault: catIsDefault)
                cat.group = group
                context.insert(cat)
            }

            try context.save()
            return group
        }
    }

    func updateGroup(_ group: SDGroup) async throws {
        try await MainActor.run {
            group.lastModifiedAt = Date()
            try context.save()
        }
    }

    func deleteGroup(id: UUID) async throws {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDGroup>(predicate: #Predicate { $0.id == targetId })
            guard let group = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            context.delete(group)
            try context.save()
        }
    }

    func fetchGroups(forUserId userId: UUID) async throws -> [SDGroup] {
        try await MainActor.run {
            let targetUserId = userId
            let descriptor = FetchDescriptor<SDUserGroup>(
                predicate: #Predicate { $0.user?.id == targetUserId }
            )
            return try context.fetch(descriptor).compactMap { $0.group }
        }
    }
}
