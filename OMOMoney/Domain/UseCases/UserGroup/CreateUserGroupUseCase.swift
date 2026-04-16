import Foundation

protocol CreateUserGroupUseCase {
    func execute(userId: UUID, groupId: UUID, role: String) async throws -> SDUserGroup
}

final class DefaultCreateUserGroupUseCase: CreateUserGroupUseCase {
    private let userGroupRepository: UserGroupRepository

    init(userGroupRepository: UserGroupRepository) {
        self.userGroupRepository = userGroupRepository
    }

    func execute(userId: UUID, groupId: UUID, role: String = "member") async throws -> SDUserGroup {
        let trimmedRole = role.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRole.isEmpty else { throw ValidationError.invalidRole }
        return try await userGroupRepository.createUserGroup(userId: userId, groupId: groupId, role: trimmedRole)
    }
}
