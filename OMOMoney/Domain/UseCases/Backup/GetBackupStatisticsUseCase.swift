import Foundation

protocol GetBackupStatisticsUseCase {
    func execute() async throws -> OMOBackupStatistics
}

final class DefaultGetBackupStatisticsUseCase: GetBackupStatisticsUseCase {
    private let backupRepository: BackupRepository

    init(backupRepository: BackupRepository) {
        self.backupRepository = backupRepository
    }

    func execute() async throws -> OMOBackupStatistics {
        try await backupRepository.currentStatistics()
    }
}
