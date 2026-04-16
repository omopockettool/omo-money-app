import Foundation

protocol FetchGroupsForUserUseCase {
    func execute(userId: UUID) async throws -> [SDGroup]
}

final class DefaultFetchGroupsForUserUseCase: FetchGroupsForUserUseCase {
    private let groupRepository: GroupRepository

    init(groupRepository: GroupRepository) {
        self.groupRepository = groupRepository
    }

    func execute(userId: UUID) async throws -> [SDGroup] {
        return try await groupRepository.fetchGroups(forUserId: userId)
    }
}
