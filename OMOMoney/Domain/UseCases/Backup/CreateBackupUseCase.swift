import Foundation

protocol CreateBackupUseCase {
    func execute(appName: String, bundleIdentifier: String, appVersion: String, exportedAt: Date) async throws -> OMOBackupEnvelope
}

final class DefaultCreateBackupUseCase: CreateBackupUseCase {
    private let backupRepository: BackupRepository

    init(backupRepository: BackupRepository) {
        self.backupRepository = backupRepository
    }

    func execute(appName: String, bundleIdentifier: String, appVersion: String, exportedAt: Date) async throws -> OMOBackupEnvelope {
        try await backupRepository.makeBackup(
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            appVersion: appVersion,
            exportedAt: exportedAt
        )
    }
}
