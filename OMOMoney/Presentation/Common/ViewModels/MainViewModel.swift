import Foundation
import OSLog

@MainActor
@Observable
final class MainViewModel {
    var hasUsers = false
    var isLoading = true

    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let minimumSplashDisplayTime: TimeInterval
    private let logger = Logger(subsystem: "OMOMoney", category: "Lifecycle.MainViewModel")

    init(
        getCurrentUserUseCase: GetCurrentUserUseCase,
        minimumSplashDisplayTime: TimeInterval = 1.2
    ) {
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.minimumSplashDisplayTime = minimumSplashDisplayTime
    }

    convenience init() {
        let container = AppDIContainer.shared
        self.init(getCurrentUserUseCase: container.makeGetCurrentUserUseCase())
    }

    func checkForUsers() async {
        logger.debug("checkForUsers started")
        isLoading = true
        let startTime = Date()

        do {
            let currentUser = try await getCurrentUserUseCase.execute()
            await keepSplashVisible(from: startTime)
            hasUsers = currentUser != nil
            logger.debug("checkForUsers succeeded hasUsers=\(self.hasUsers)")
        } catch {
            await keepSplashVisible(from: startTime)
            hasUsers = false
            logger.error("checkForUsers failed: \(error.localizedDescription)")
        }

        isLoading = false
        logger.debug("checkForUsers finished isLoading=\(self.isLoading)")
    }

    private func keepSplashVisible(from startTime: Date) async {
        let elapsed = Date().timeIntervalSince(startTime)
        let remainingTime = minimumSplashDisplayTime - elapsed
        guard remainingTime > 0 else { return }

        try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
    }
}
