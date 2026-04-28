import Foundation

@MainActor
@Observable
final class MainViewModel {
    var hasUsers = false
    var isLoading = true

    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let minimumSplashDisplayTime: TimeInterval

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
        isLoading = true
        let startTime = Date()

        do {
            let currentUser = try await getCurrentUserUseCase.execute()
            await keepSplashVisible(from: startTime)
            hasUsers = currentUser != nil
        } catch {
            await keepSplashVisible(from: startTime)
            hasUsers = false
        }

        isLoading = false
    }

    private func keepSplashVisible(from startTime: Date) async {
        let elapsed = Date().timeIntervalSince(startTime)
        let remainingTime = minimumSplashDisplayTime - elapsed
        guard remainingTime > 0 else { return }

        try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
    }
}
