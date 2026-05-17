import Foundation
import SwiftData

@MainActor
final class DefaultGroupRepository: GroupRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchGroup(id: UUID) async throws -> SDGroup? {
        let targetId = id
        let descriptor = FetchDescriptor<SDGroup>(predicate: #Predicate { $0.id == targetId })
        return try context.fetch(descriptor).first
    }

    func createGroup(name: String, currency: String) async throws -> SDGroup {
        let group = SDGroup(name: name, currency: currency)
        context.insert(group)

        let defaultPaymentMethods: [(String, String, String, String)] = [
            ("Efectivo",      "cash",          "banknote.fill",          "#4CAF50"),
            ("Débito",        "card_debit",    "creditcard.fill",        "#2196F3"),
            ("Crédito",       "card_credit",   "creditcard.fill",        "#9C27B0"),
            ("Transferencia", "bank_transfer", "arrow.left.arrow.right", "#FF9800")
        ]
        for (pmName, pmType, pmIcon, pmColor) in defaultPaymentMethods {
            let pm = SDPaymentMethod(name: pmName, type: pmType, icon: pmIcon, color: pmColor, isActive: true)
            pm.group = group
            context.insert(pm)
        }

        let defaultCategories: [(String, String, String, Int, Double, String)] = [
            ("Alimentación", "#FF6B6B", "cart.fill",            0, 300, "monthly"),
            ("Movilidad",    "#4ECDC4", "car.fill",             0, 100, "monthly"),
            ("Hogar",        "#45B7D1", "house.fill",           0, 700, "monthly"),
            ("Ocio",         "#96CEB4", "theatermasks.fill",    0, 200, "monthly"),
            ("Salud",        "#FFEAA7", "heart.fill",           0, 50, "monthly"),
            ("Moda",         "#ffa7ed", "tshirt.fill",          0, 100, "monthly"),
        ]
        for (catName, catColor, catIcon, catSortOrder, catLimit, catLimitFrequency) in defaultCategories {
            let cat = SDCategory(
                name: catName,
                color: catColor,
                icon: catIcon,
                sortOrder: catSortOrder,
                limit: catLimit,
                limitFrequency: catLimitFrequency
            )
            cat.group = group
            context.insert(cat)
        }

        try context.save()
        return group
    }

    func updateGroup(_ group: SDGroup) async throws {
        group.lastModifiedAt = Date()
        try context.save()
    }

    func deleteGroup(id: UUID) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<SDGroup>(predicate: #Predicate { $0.id == targetId })
        guard let group = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(group)
        try context.save()
    }

    func fetchGroups(forUserId userId: UUID) async throws -> [SDGroup] {
        let targetUserId = userId
        let descriptor = FetchDescriptor<SDUserGroup>(
            predicate: #Predicate { $0.user?.id == targetUserId }
        )
        return try context.fetch(descriptor).compactMap { $0.group }
    }
}
