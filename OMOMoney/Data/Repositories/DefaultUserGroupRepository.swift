import Foundation
import SwiftData

@MainActor
final class DefaultUserGroupRepository: UserGroupRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchUserGroups() async throws -> [SDUserGroup] {
        let descriptor = FetchDescriptor<SDUserGroup>()
        return try context.fetch(descriptor)
    }

    func fetchUserGroup(id: UUID) async throws -> SDUserGroup? {
        let targetId = id
        let descriptor = FetchDescriptor<SDUserGroup>(predicate: #Predicate { $0.id == targetId })
        return try context.fetch(descriptor).first
    }

    func fetchUserGroups(forUserId userId: UUID) async throws -> [SDUserGroup] {
        let targetUserId = userId
        let descriptor = FetchDescriptor<SDUserGroup>(
            predicate: #Predicate { $0.user?.id == targetUserId }
        )
        return try context.fetch(descriptor)
    }

    func fetchUserGroups(forGroupId groupId: UUID) async throws -> [SDUserGroup] {
        let targetGroupId = groupId
        let descriptor = FetchDescriptor<SDUserGroup>(
            predicate: #Predicate { $0.group?.id == targetGroupId }
        )
        return try context.fetch(descriptor)
    }

    func createUserGroup(userId: UUID, groupId: UUID, role: String) async throws -> SDUserGroup {
        let userGroup = SDUserGroup(role: role)

        let targetUserId = userId
        let userDescriptor = FetchDescriptor<SDUser>(predicate: #Predicate { $0.id == targetUserId })
        userGroup.user = try context.fetch(userDescriptor).first

        let targetGroupId = groupId
        let groupDescriptor = FetchDescriptor<SDGroup>(predicate: #Predicate { $0.id == targetGroupId })
        userGroup.group = try context.fetch(groupDescriptor).first

        context.insert(userGroup)
        try context.save()
        return userGroup
    }

    func updateUserGroup(_ userGroup: SDUserGroup) async throws {
        try context.save()
    }

    func deleteUserGroup(id: UUID) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<SDUserGroup>(predicate: #Predicate { $0.id == targetId })
        guard let userGroup = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(userGroup)
        try context.save()
    }

    func removeUser(_ userId: UUID, fromGroup groupId: UUID) async throws {
        let targetUserId = userId
        let targetGroupId = groupId
        let descriptor = FetchDescriptor<SDUserGroup>(
            predicate: #Predicate { $0.user?.id == targetUserId && $0.group?.id == targetGroupId }
        )
        guard let userGroup = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(userGroup)
        try context.save()
    }
}
