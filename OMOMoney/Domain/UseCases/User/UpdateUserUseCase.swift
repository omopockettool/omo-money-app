import Foundation

protocol UpdateUserUseCase {
    func execute(user: SDUser) async throws
}

final class DefaultUpdateUserUseCase: UpdateUserUseCase {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func execute(user: SDUser) async throws {
        try user.validate()
        try await userRepository.updateUser(user)
    }
}
