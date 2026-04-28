import Foundation

@MainActor
@Observable
final class AppContentViewModel {
    var isLoading = true
    var isSetupComplete = false
    var errorMessage: String?

    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let fetchGroupsForUserUseCase: FetchGroupsForUserUseCase

    init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        fetchGroupsForUserUseCase: FetchGroupsForUserUseCase
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.fetchGroupsForUserUseCase = fetchGroupsForUserUseCase
    }

    convenience init() {
        let container = AppDIContainer.shared
        self.init(
            getCurrentUserUseCase: container.makeGetCurrentUserUseCase(),
            fetchGroupsForUserUseCase: container.makeFetchGroupsForUserUseCase()
        )
    }

    func loadInitialData() async {
        isLoading = true
        errorMessage = nil

        do {
            guard let currentUser = try await getCurrentUserUseCase.execute() else {
                isSetupComplete = false
                isLoading = false
                return
            }

            let groups = try await fetchGroupsForUserUseCase.execute(userId: currentUser.id)
            isSetupComplete = !groups.isEmpty
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isSetupComplete = false
            isLoading = false
        }
    }
}
