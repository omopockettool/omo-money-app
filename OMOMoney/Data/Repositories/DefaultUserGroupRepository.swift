import Foundation
import SwiftData

final class DefaultUserGroupRepository: UserGroupRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchUserGroups() async throws -> [UserGroupDomain] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<SDUserGroup>()
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func fetchUserGroup(id: UUID) async throws -> UserGroupDomain? {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDUserGroup>(predicate: #Predicate { $0.id == targetId })
            return try context.fetch(descriptor).first?.toDomain()
        }
    }

    func fetchUserGroups(forUserId userId: UUID) async throws -> [UserGroupDomain] {
        try await MainActor.run {
            let targetUserId = userId
            let descriptor = FetchDescriptor<SDUserGroup>(
                predicate: #Predicate { $0.user?.id == targetUserId }
            )
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func fetchUserGroups(forGroupId groupId: UUID) async throws -> [UserGroupDomain] {
        try await MainActor.run {
            let targetGroupId = groupId
            let descriptor = FetchDescriptor<SDUserGroup>(
                predicate: #Predicate { $0.group?.id == targetGroupId }
            )
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func createUserGroup(userId: UUID, groupId: UUID, role: String) async throws -> UserGroupDomain {
        try await MainActor.run {
            let userGroup = SDUserGroup(role: role)

            let targetUserId = userId
            let userDescriptor = FetchDescriptor<SDUser>(predicate: #Predicate { $0.id == targetUserId })
            userGroup.user = try context.fetch(userDescriptor).first

            let targetGroupId = groupId
            let groupDescriptor = FetchDescriptor<SDGroup>(predicate: #Predicate { $0.id == targetGroupId })
            userGroup.group = try context.fetch(groupDescriptor).first

            context.insert(userGroup)
            try context.save()
            return userGroup.toDomain()
        }
    }

    func updateUserGroup(_ userGroup: UserGroupDomain) async throws {
        try await MainActor.run {
            let targetId = userGroup.id
            let descriptor = FetchDescriptor<SDUserGroup>(predicate: #Predicate { $0.id == targetId })
            guard let existing = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            existing.role = userGroup.role
            try context.save()
        }
    }

    func deleteUserGroup(id: UUID) async throws {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDUserGroup>(predicate: #Predicate { $0.id == targetId })
            guard let userGroup = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            context.delete(userGroup)
            try context.save()
        }
    }

    func removeUser(_ userId: UUID, fromGroup groupId: UUID) async throws {
        try await MainActor.run {
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
}

// MARK: - Domain mapping
private extension SDUserGroup {
    func toDomain() -> UserGroupDomain {
        UserGroupDomain(
            id: id,
            userId: user?.id ?? UUID(),
            groupId: group?.id ?? UUID(),
            role: role,
            joinedAt: joinedAt
        )
    }
}
