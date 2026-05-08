import Foundation

protocol BackupRepository {
    func makeBackup(appName: String, bundleIdentifier: String, appVersion: String, exportedAt: Date) async throws -> OMOBackupEnvelope
    func replaceAllData(with backup: OMOBackupEnvelope) async throws
    func currentStatistics() async throws -> OMOBackupStatistics
}
