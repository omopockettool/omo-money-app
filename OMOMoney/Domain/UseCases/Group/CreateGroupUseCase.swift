import Foundation

protocol CreateGroupUseCase {
    func execute(name: String, currency: String) async throws -> SDGroup
}

final class DefaultCreateGroupUseCase: CreateGroupUseCase {
    private let groupRepository: GroupRepository

    init(groupRepository: GroupRepository) {
        self.groupRepository = groupRepository
    }

    func execute(name: String, currency: String = "USD") async throws -> SDGroup {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCurrency = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmedName.isEmpty else { throw ValidationError.emptyGroupName }
        guard !trimmedCurrency.isEmpty else { throw ValidationError.invalidAmount }
        return try await groupRepository.createGroup(name: trimmedName, currency: trimmedCurrency)
    }
}
