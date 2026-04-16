import Foundation

protocol GetCurrentUserUseCase {
    func execute() async throws -> SDUser?
}

final class DefaultGetCurrentUserUseCase: GetCurrentUserUseCase {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func execute() async throws -> SDUser? {
        return try await userRepository.fetchUsers().first
    }
}
