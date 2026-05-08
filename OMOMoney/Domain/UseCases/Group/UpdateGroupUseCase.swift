import Foundation

protocol UpdateGroupUseCase {
    func execute(group: SDGroup) async throws
}

final class DefaultUpdateGroupUseCase: UpdateGroupUseCase {
    private let groupRepository: GroupRepository

    init(groupRepository: GroupRepository) {
        self.groupRepository = groupRepository
    }

    func execute(group: SDGroup) async throws {
        try group.validate()
        try await groupRepository.updateGroup(group)
    }
}
