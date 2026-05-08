import Foundation
import OSLog

@MainActor
@Observable
final class AppContentViewModel {
    var isLoading = true
    var isSetupComplete = false
    var errorMessage: String?

    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let fetchGroupsForUserUseCase: FetchGroupsForUserUseCase
    private let logger = Logger(subsystem: "OMOMoney", category: "Lifecycle.AppContentViewModel")

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
        logger.debug("loadInitialData started")
        isLoading = true
        errorMessage = nil

        do {
            guard let currentUser = try await getCurrentUserUseCase.execute() else {
                isSetupComplete = false
                isLoading = false
                logger.debug("loadInitialData finished without current user")
                return
            }

            let groups = try await fetchGroupsForUserUseCase.execute(userId: currentUser.id)
            isSetupComplete = !groups.isEmpty
            isLoading = false
            logger.debug("loadInitialData succeeded groupsCount=\(groups.count) setupComplete=\(self.isSetupComplete)")
        } catch {
            errorMessage = error.localizedDescription
            isSetupComplete = false
            isLoading = false
            logger.error("loadInitialData failed: \(error.localizedDescription)")
        }
    }
}
