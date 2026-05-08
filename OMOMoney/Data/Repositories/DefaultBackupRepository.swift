import Foundation
import SwiftData

@MainActor
final class DefaultBackupRepository: BackupRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func makeBackup(appName: String, bundleIdentifier: String, appVersion: String, exportedAt: Date) async throws -> OMOBackupEnvelope {
        let users = try context.fetch(FetchDescriptor<SDUser>()).sorted(using: \.createdAt, then: \.id)
        let groups = try context.fetch(FetchDescriptor<SDGroup>()).sorted(using: \.createdAt, then: \.id)
        let userGroups = try context.fetch(FetchDescriptor<SDUserGroup>()).sorted(using: \.joinedAt, then: \.id)
        let categories = try context.fetch(FetchDescriptor<SDCategory>()).sorted(using: \.createdAt, then: \.id)
        let paymentMethods = try context.fetch(FetchDescriptor<SDPaymentMethod>()).sorted(using: \.createdAt, then: \.id)
        let itemLists = try context.fetch(FetchDescriptor<SDItemList>()).sorted(using: \.createdAt, then: \.id)
        let items = try context.fetch(FetchDescriptor<SDItem>()).sorted(using: \.createdAt, then: \.id)

        let userRecords = users.map {
            OMOBackupUserRecord(
                id: $0.id,
                name: $0.name,
                email: $0.email,
                createdAt: $0.createdAt,
                lastModifiedAt: $0.lastModifiedAt
            )
        }

        let groupRecords = groups.map {
            OMOBackupGroupRecord(
                id: $0.id,
                name: $0.name,
                currency: $0.currency,
                createdAt: $0.createdAt,
                lastModifiedAt: $0.lastModifiedAt
            )
        }

        let userGroupRecords = userGroups.map {
            OMOBackupUserGroupRecord(
                id: $0.id,
                role: $0.role,
                joinedAt: $0.joinedAt,
                userID: $0.user?.id,
                groupID: $0.group?.id
            )
        }

        let categoryRecords = categories.map {
            OMOBackupCategoryRecord(
                id: $0.id,
                name: $0.name,
                color: $0.color,
                icon: $0.icon,
                sortOrder: $0.sortOrder,
                limit: $0.limit,
                limitFrequency: $0.limitFrequency,
                createdAt: $0.createdAt,
                lastModifiedAt: $0.lastModifiedAt,
                groupID: $0.group?.id
            )
        }

        let paymentMethodRecords = paymentMethods.map {
            OMOBackupPaymentMethodRecord(
                id: $0.id,
                name: $0.name,
                type: $0.type,
                icon: $0.icon,
                color: $0.color,
                isActive: $0.isActive,
                createdAt: $0.createdAt,
                lastModifiedAt: $0.lastModifiedAt,
                groupID: $0.group?.id
            )
        }

        let itemListRecords = itemLists.map {
            OMOBackupItemListRecord(
                id: $0.id,
                itemListDescription: $0.itemListDescription,
                date: $0.date,
                createdAt: $0.createdAt,
                lastModifiedAt: $0.lastModifiedAt,
                groupID: $0.group?.id,
                categoryID: $0.category?.id,
                paymentMethodID: $0.paymentMethod?.id
            )
        }

        let itemRecords = items.map {
            OMOBackupItemRecord(
                id: $0.id,
                itemDescription: $0.itemDescription,
                amount: $0.amount,
                quantity: $0.quantity,
                isPaid: $0.isPaid,
                createdAt: $0.createdAt,
                lastModifiedAt: $0.lastModifiedAt,
                itemListID: $0.itemList?.id
            )
        }

        let statistics = OMOBackupStatistics(
            users: userRecords.count,
            groups: groupRecords.count,
            userGroups: userGroupRecords.count,
            categories: categoryRecords.count,
            paymentMethods: paymentMethodRecords.count,
            itemLists: itemListRecords.count,
            items: itemRecords.count
        )

        return OMOBackupEnvelope(
            schemaVersion: OMOBackupEnvelope.currentSchemaVersion,
            exportedAt: exportedAt,
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            appVersion: appVersion,
            statistics: statistics,
            users: userRecords,
            groups: groupRecords,
            userGroups: userGroupRecords,
            categories: categoryRecords,
            paymentMethods: paymentMethodRecords,
            itemLists: itemListRecords,
            items: itemRecords
        )
    }

    func replaceAllData(with backup: OMOBackupEnvelope) async throws {
        try backup.validate()
        try deleteExistingData()

        var usersByID: [UUID: SDUser] = [:]
        var groupsByID: [UUID: SDGroup] = [:]
        var categoriesByID: [UUID: SDCategory] = [:]
        var paymentMethodsByID: [UUID: SDPaymentMethod] = [:]
        var itemListsByID: [UUID: SDItemList] = [:]

        for record in backup.users {
            let user = SDUser(
                id: record.id,
                name: record.name,
                email: record.email,
                createdAt: record.createdAt,
                lastModifiedAt: record.lastModifiedAt
            )
            context.insert(user)
            usersByID[record.id] = user
        }

        for record in backup.groups {
            let group = SDGroup(
                id: record.id,
                name: record.name,
                currency: record.currency,
                createdAt: record.createdAt,
                lastModifiedAt: record.lastModifiedAt
            )
            context.insert(group)
            groupsByID[record.id] = group
        }

        for record in backup.categories {
            let category = SDCategory(
                id: record.id,
                name: record.name,
                color: record.color,
                icon: record.icon,
                sortOrder: record.sortOrder,
                limit: record.limit,
                limitFrequency: record.limitFrequency,
                createdAt: record.createdAt,
                lastModifiedAt: record.lastModifiedAt
            )
            if let groupID = record.groupID {
                category.group = groupsByID[groupID]
            }
            context.insert(category)
            categoriesByID[record.id] = category
        }

        for record in backup.paymentMethods {
            let method = SDPaymentMethod(
                id: record.id,
                name: record.name,
                type: record.type,
                icon: record.icon,
                color: record.color,
                isActive: record.isActive,
                createdAt: record.createdAt,
                lastModifiedAt: record.lastModifiedAt
            )
            if let groupID = record.groupID {
                method.group = groupsByID[groupID]
            }
            context.insert(method)
            paymentMethodsByID[record.id] = method
        }

        for record in backup.itemLists {
            let itemList = SDItemList(
                id: record.id,
                itemListDescription: record.itemListDescription,
                date: record.date,
                createdAt: record.createdAt,
                lastModifiedAt: record.lastModifiedAt
            )
            if let groupID = record.groupID {
                itemList.group = groupsByID[groupID]
            }
            if let categoryID = record.categoryID {
                itemList.category = categoriesByID[categoryID]
            }
            if let paymentMethodID = record.paymentMethodID {
                itemList.paymentMethod = paymentMethodsByID[paymentMethodID]
            }
            context.insert(itemList)
            itemListsByID[record.id] = itemList
        }

        for record in backup.items {
            let item = SDItem(
                id: record.id,
                itemDescription: record.itemDescription,
                amount: record.amount,
                quantity: record.quantity,
                isPaid: record.isPaid,
                createdAt: record.createdAt,
                lastModifiedAt: record.lastModifiedAt
            )
            if let itemListID = record.itemListID {
                item.itemList = itemListsByID[itemListID]
            }
            context.insert(item)
        }

        for record in backup.userGroups {
            let userGroup = SDUserGroup(
                id: record.id,
                role: record.role,
                joinedAt: record.joinedAt
            )
            if let userID = record.userID {
                userGroup.user = usersByID[userID]
            }
            if let groupID = record.groupID {
                userGroup.group = groupsByID[groupID]
            }
            context.insert(userGroup)
        }

        try context.safeSave()
    }

    func currentStatistics() async throws -> OMOBackupStatistics {
        OMOBackupStatistics(
            users: try context.fetchCount(FetchDescriptor<SDUser>()),
            groups: try context.fetchCount(FetchDescriptor<SDGroup>()),
            userGroups: try context.fetchCount(FetchDescriptor<SDUserGroup>()),
            categories: try context.fetchCount(FetchDescriptor<SDCategory>()),
            paymentMethods: try context.fetchCount(FetchDescriptor<SDPaymentMethod>()),
            itemLists: try context.fetchCount(FetchDescriptor<SDItemList>()),
            items: try context.fetchCount(FetchDescriptor<SDItem>())
        )
    }

    private func deleteExistingData() throws {
        try context.fetch(FetchDescriptor<SDItem>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<SDItemList>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<SDCategory>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<SDPaymentMethod>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<SDUserGroup>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<SDGroup>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<SDUser>()).forEach(context.delete)
        try context.safeSave()
    }
}

private extension Array {
    func sorted<Value: Comparable>(using first: KeyPath<Element, Value>, then second: KeyPath<Element, UUID>) -> [Element] {
        sorted {
            let lhsPrimary = $0[keyPath: first]
            let rhsPrimary = $1[keyPath: first]
            if lhsPrimary == rhsPrimary {
                return $0[keyPath: second].uuidString < $1[keyPath: second].uuidString
            }
            return lhsPrimary < rhsPrimary
        }
    }
}
