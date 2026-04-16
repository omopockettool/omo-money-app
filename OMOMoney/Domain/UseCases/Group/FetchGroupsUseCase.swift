import Foundation

protocol FetchGroupsUseCase {
    func execute(forUserId userId: UUID) async throws -> [SDGroup]
}

final class DefaultFetchGroupsUseCase: FetchGroupsUseCase {
    private let groupRepository: GroupRepository

    init(groupRepository: GroupRepository) {
        self.groupRepository = groupRepository
    }

    func execute(forUserId userId: UUID) async throws -> [SDGroup] {
        return try await groupRepository.fetchGroups(forUserId: userId).filter { $0.isValid }
    }
}
