import Foundation

protocol ImportBackupUseCase {
    func execute(backup: OMOBackupEnvelope) async throws
}

final class DefaultImportBackupUseCase: ImportBackupUseCase {
    private let backupRepository: BackupRepository

    init(backupRepository: BackupRepository) {
        self.backupRepository = backupRepository
    }

    func execute(backup: OMOBackupEnvelope) async throws {
        try backup.validate()
        try await backupRepository.replaceAllData(with: backup)
    }
}
