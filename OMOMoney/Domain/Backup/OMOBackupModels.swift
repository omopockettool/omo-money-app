import Foundation

struct OMOBackupEnvelope: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let appName: String
    let bundleIdentifier: String
    let appVersion: String
    let statistics: OMOBackupStatistics
    let users: [OMOBackupUserRecord]
    let groups: [OMOBackupGroupRecord]
    let userGroups: [OMOBackupUserGroupRecord]
    let categories: [OMOBackupCategoryRecord]
    let paymentMethods: [OMOBackupPaymentMethodRecord]
    let itemLists: [OMOBackupItemListRecord]
    let items: [OMOBackupItemRecord]

    static let currentSchemaVersion = 1
}

struct OMOBackupStatistics: Codable {
    let users: Int
    let groups: Int
    let userGroups: Int
    let categories: Int
    let paymentMethods: Int
    let itemLists: Int
    let items: Int

    var totalEntityCount: Int {
        users + groups + userGroups + categories + paymentMethods + itemLists + items
    }
}

struct OMOBackupUserRecord: Codable {
    let id: UUID
    let name: String
    let email: String
    let createdAt: Date
    let lastModifiedAt: Date?
}

struct OMOBackupGroupRecord: Codable {
    let id: UUID
    let name: String
    let currency: String
    let createdAt: Date
    let lastModifiedAt: Date?
}

struct OMOBackupUserGroupRecord: Codable {
    let id: UUID
    let role: String
    let joinedAt: Date
    let userID: UUID?
    let groupID: UUID?
}

struct OMOBackupCategoryRecord: Codable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
    let sortOrder: Int
    let limit: Double?
    let limitFrequency: String
    let createdAt: Date
    let lastModifiedAt: Date?
    let groupID: UUID?
}

struct OMOBackupPaymentMethodRecord: Codable {
    let id: UUID
    let name: String
    let type: String
    let icon: String
    let color: String
    let isActive: Bool
    let createdAt: Date
    let lastModifiedAt: Date?
    let groupID: UUID?
}

struct OMOBackupItemListRecord: Codable {
    let id: UUID
    let itemListDescription: String
    let date: Date
    let createdAt: Date
    let lastModifiedAt: Date?
    let groupID: UUID?
    let categoryID: UUID?
    let paymentMethodID: UUID?
}

struct OMOBackupItemRecord: Codable {
    let id: UUID
    let itemDescription: String
    let amount: Double
    let quantity: Int
    let isPaid: Bool
    let createdAt: Date
    let lastModifiedAt: Date?
    let itemListID: UUID?
}

enum OMOBackupError: LocalizedError {
    case unsupportedSchemaVersion(Int)
    case missingCoreData(entity: String)
    case duplicateIdentifier(entity: String, id: UUID)
    case missingReference(entity: String, relation: String, id: UUID)
    case statisticsMismatch
    case invalidFileContents

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "Unsupported backup version: \(version)."
        case .missingCoreData(let entity):
            return "The backup is missing required \(entity) data."
        case .duplicateIdentifier(let entity, let id):
            return "The backup contains a duplicate \(entity) identifier: \(id.uuidString)."
        case .missingReference(let entity, let relation, let id):
            return "The backup contains a \(entity) that references a missing \(relation): \(id.uuidString)."
        case .statisticsMismatch:
            return "The backup statistics don't match the payload contents."
        case .invalidFileContents:
            return "The selected file doesn't contain a valid OMO backup."
        }
    }
}

extension OMOBackupEnvelope {
    func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw OMOBackupError.unsupportedSchemaVersion(schemaVersion)
        }

        guard !users.isEmpty else {
            throw OMOBackupError.missingCoreData(entity: "user")
        }

        guard !groups.isEmpty else {
            throw OMOBackupError.missingCoreData(entity: "group")
        }

        guard !userGroups.isEmpty else {
            throw OMOBackupError.missingCoreData(entity: "user-group")
        }

        let computedStatistics = OMOBackupStatistics(
            users: users.count,
            groups: groups.count,
            userGroups: userGroups.count,
            categories: categories.count,
            paymentMethods: paymentMethods.count,
            itemLists: itemLists.count,
            items: items.count
        )

        guard
            statistics.users == computedStatistics.users,
            statistics.groups == computedStatistics.groups,
            statistics.userGroups == computedStatistics.userGroups,
            statistics.categories == computedStatistics.categories,
            statistics.paymentMethods == computedStatistics.paymentMethods,
            statistics.itemLists == computedStatistics.itemLists,
            statistics.items == computedStatistics.items
        else {
            throw OMOBackupError.statisticsMismatch
        }

        try validateUniqueIdentifiers(users.map(\.id), entity: "user")
        try validateUniqueIdentifiers(groups.map(\.id), entity: "group")
        try validateUniqueIdentifiers(userGroups.map(\.id), entity: "user-group")
        try validateUniqueIdentifiers(categories.map(\.id), entity: "category")
        try validateUniqueIdentifiers(paymentMethods.map(\.id), entity: "payment method")
        try validateUniqueIdentifiers(itemLists.map(\.id), entity: "item list")
        try validateUniqueIdentifiers(items.map(\.id), entity: "item")

        let userIDs = Set(users.map(\.id))
        let groupIDs = Set(groups.map(\.id))
        let categoryIDs = Set(categories.map(\.id))
        let paymentMethodIDs = Set(paymentMethods.map(\.id))
        let itemListIDs = Set(itemLists.map(\.id))

        for record in userGroups {
            if let userID = record.userID, !userIDs.contains(userID) {
                throw OMOBackupError.missingReference(entity: "user-group", relation: "user", id: userID)
            }
            if let groupID = record.groupID, !groupIDs.contains(groupID) {
                throw OMOBackupError.missingReference(entity: "user-group", relation: "group", id: groupID)
            }
        }

        for record in categories {
            if let groupID = record.groupID, !groupIDs.contains(groupID) {
                throw OMOBackupError.missingReference(entity: "category", relation: "group", id: groupID)
            }
        }

        for record in paymentMethods {
            if let groupID = record.groupID, !groupIDs.contains(groupID) {
                throw OMOBackupError.missingReference(entity: "payment method", relation: "group", id: groupID)
            }
        }

        for record in itemLists {
            if let groupID = record.groupID, !groupIDs.contains(groupID) {
                throw OMOBackupError.missingReference(entity: "item list", relation: "group", id: groupID)
            }
            if let categoryID = record.categoryID, !categoryIDs.contains(categoryID) {
                throw OMOBackupError.missingReference(entity: "item list", relation: "category", id: categoryID)
            }
            if let paymentMethodID = record.paymentMethodID, !paymentMethodIDs.contains(paymentMethodID) {
                throw OMOBackupError.missingReference(entity: "item list", relation: "payment method", id: paymentMethodID)
            }
        }

        for record in items {
            if let itemListID = record.itemListID, !itemListIDs.contains(itemListID) {
                throw OMOBackupError.missingReference(entity: "item", relation: "item list", id: itemListID)
            }
        }
    }

    private func validateUniqueIdentifiers(_ ids: [UUID], entity: String) throws {
        var seen = Set<UUID>()
        for id in ids where !seen.insert(id).inserted {
            throw OMOBackupError.duplicateIdentifier(entity: entity, id: id)
        }
    }
}
