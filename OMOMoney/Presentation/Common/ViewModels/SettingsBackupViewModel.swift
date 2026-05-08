import Foundation

@MainActor
@Observable
final class SettingsBackupViewModel {
    enum ExportPurpose {
        case manual
        case rescueBeforeImport
    }

    var exportDocument = OMOBackupDocument(data: Data())
    var exportFilename = ""
    var isShowingExporter = false
    var isShowingImporter = false
    var isShowingRescueExplanation = false
    var isShowingReplaceConfirmation = false
    var isWorking = false
    var pendingImportedBackup: OMOBackupEnvelope?
    var pendingExportPurpose: ExportPurpose = .manual
    var errorMessage: String?
    var toast: ToastMessage?

    private let createBackupUseCase: CreateBackupUseCase
    private let importBackupUseCase: ImportBackupUseCase
    private let getBackupStatisticsUseCase: GetBackupStatisticsUseCase

    init(
        createBackupUseCase: CreateBackupUseCase,
        importBackupUseCase: ImportBackupUseCase,
        getBackupStatisticsUseCase: GetBackupStatisticsUseCase
    ) {
        self.createBackupUseCase = createBackupUseCase
        self.importBackupUseCase = importBackupUseCase
        self.getBackupStatisticsUseCase = getBackupStatisticsUseCase
    }

    func beginManualExport() {
        guard canStartNewFlow else { return }
        Task {
            await prepareExport(purpose: .manual)
        }
    }

    func beginImport() {
        guard canStartNewFlow else { return }
        isShowingImporter = true
    }

    func handleExportCompletion(_ result: Result<URL, Error>) {
        isShowingExporter = false

        switch result {
        case .success:
            switch pendingExportPurpose {
            case .manual:
                toast = ToastMessage("Backup saved to Files.", type: .info)
                resetExportMetadata()
            case .rescueBeforeImport:
                resetExportMetadata()
                isShowingReplaceConfirmation = true
            }
        case .failure(let error):
            if isCancellation(error) {
                if pendingExportPurpose == .rescueBeforeImport {
                    pendingImportedBackup = nil
                    toast = ToastMessage("Import cancelled. Save the rescue backup to continue.", type: .warning)
                }
                resetExportMetadata()
                return
            }

            if pendingExportPurpose == .rescueBeforeImport {
                pendingImportedBackup = nil
            }

            resetExportMetadata()
            errorMessage = error.localizedDescription
        }
    }

    func handleImportSelection(_ result: Result<URL, Error>) {
        isShowingImporter = false

        switch result {
        case .success(let url):
            Task {
                await prepareImport(from: url)
            }
        case .failure(let error):
            guard !isCancellation(error) else { return }
            errorMessage = error.localizedDescription
        }
    }

    func confirmReplaceImport(onImported: @escaping () async -> Void) {
        guard let backup = pendingImportedBackup else { return }

        isShowingReplaceConfirmation = false
        isWorking = true

        Task {
            defer {
                isWorking = false
                pendingImportedBackup = nil
            }

            do {
                try await importBackupUseCase.execute(backup: backup)
                await onImported()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func cancelReplaceImport() {
        isShowingReplaceConfirmation = false
        pendingImportedBackup = nil
    }

    private func prepareExport(purpose: ExportPurpose) async {
        isWorking = true
        defer { isWorking = false }

        do {
            let backup = try await createBackupUseCase.execute(
                appName: appDisplayName,
                bundleIdentifier: bundleIdentifier,
                appVersion: appVersion,
                exportedAt: Date()
            )

            let data = try backupData(from: backup)
            exportFilename = makeFilename(prefix: purpose == .manual ? "omo-backup" : "omo-rescue-backup")
            exportDocument = OMOBackupDocument(data: data)
            pendingExportPurpose = purpose
            isShowingExporter = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func prepareImport(from url: URL) async {
        isWorking = true
        defer { isWorking = false }

        do {
            let data = try readData(from: url)
            let decoded = try decodeBackup(from: data)
            try decoded.validate()

            let statistics = try await getBackupStatisticsUseCase.execute()
            pendingImportedBackup = decoded

            if statistics.totalEntityCount > 0 {
                isShowingRescueExplanation = true
            } else {
                isShowingReplaceConfirmation = true
            }
        } catch {
            pendingImportedBackup = nil
            errorMessage = error.localizedDescription
        }
    }

    func confirmRescueExport() {
        isShowingRescueExplanation = false
        Task {
            await prepareExport(purpose: .rescueBeforeImport)
        }
    }

    func cancelRescueExport() {
        isShowingRescueExplanation = false
        pendingImportedBackup = nil
    }

    private func backupData(from backup: OMOBackupEnvelope) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    private func decodeBackup(from data: Data) throws -> OMOBackupEnvelope {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(OMOBackupEnvelope.self, from: data)
    }

    private func readData(from url: URL) throws -> Data {
        let needsScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try Data(contentsOf: url)
    }

    private func makeFilename(prefix: String) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())

        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        return String(
            format: "%@-%04d-%02d-%02d-%02d-%02d.omo-backup",
            prefix,
            year,
            month,
            day,
            hour,
            minute
        )
    }

    private func resetExportMetadata() {
        exportFilename = ""
        pendingExportPurpose = .manual
    }

    private func isCancellation(_ error: Error) -> Bool {
        if let cocoaError = error as? CocoaError, cocoaError.code == .userCancelled {
            return true
        }
        return false
    }

    private var appDisplayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "OMO Money"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.omo.OMOMoney"
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var canStartNewFlow: Bool {
        !isWorking
        && !isShowingExporter
        && !isShowingImporter
        && !isShowingRescueExplanation
        && !isShowingReplaceConfirmation
    }
}
