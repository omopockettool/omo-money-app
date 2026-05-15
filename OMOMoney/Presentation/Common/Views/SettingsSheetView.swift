import SwiftUI

struct SettingsSheetView: View {
    let user: SDUser
    let onUserUpdated: (SDUser) -> Void
    let onBackupImported: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var backupViewModel: SettingsBackupViewModel

    init(
        user: SDUser,
        onUserUpdated: @escaping (SDUser) -> Void,
        onBackupImported: @escaping () async -> Void,
        container: AppDIContainer
    ) {
        self.user = user
        self.onUserUpdated = onUserUpdated
        self.onBackupImported = onBackupImported
        _backupViewModel = State(wrappedValue: container.makeSettingsBackupViewModel())
    }

    @MainActor
    init(
        user: SDUser,
        onUserUpdated: @escaping (SDUser) -> Void,
        onBackupImported: @escaping () async -> Void
    ) {
        self.init(
            user: user,
            onUserUpdated: onUserUpdated,
            onBackupImported: onBackupImported,
            container: .shared
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        UserProfileView(user: user, onUserUpdated: onUserUpdated)
                    } label: {
                        NativeSettingsRow(systemImage: "person.fill", color: .purple, title: user.name)
                            .font(.body)
                            .padding(.vertical, 2)
                    }
                }

                Section(LocalizationKey.Settings.backup.localized) {
                    Text(LocalizationKey.Settings.backupDescription.localized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textCase(nil)

                    Button {
                        backupViewModel.beginManualExport()
                    } label: {
                        NativeSettingsRow(
                            systemImage: "square.and.arrow.up",
                            color: .green,
                            title: LocalizationKey.Settings.exportBackup.localized
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        backupViewModel.beginImport()
                    } label: {
                        NativeSettingsRow(
                            systemImage: "square.and.arrow.down",
                            color: .orange,
                            title: LocalizationKey.Settings.importBackup.localized
                        )
                    }
                    .buttonStyle(.plain)
                }

                Section("OMO") {
                    NavigationLink {
                        AboutOMOView()
                    } label: {
                        NativeSettingsRow(systemImage: "info.circle.fill", color: .blue, title: LocalizationKey.Settings.aboutOMO.localized)
                    }
                }

#if DEBUG
                Section("Debug") {
                    NavigationLink {
                        CreateFirstUserView(
                            onUserCreated: {},
                            submissionMode: .simulate
                        )
                    } label: {
                        NativeSettingsRow(
                            systemImage: "person.badge.plus",
                            color: .orange,
                            title: "Onboarding Preview"
                        )
                    }
                }
#endif
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .navigationTitle(LocalizationKey.Settings.title.localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .fileExporter(
            isPresented: $backupViewModel.isShowingExporter,
            document: backupViewModel.exportDocument,
            contentType: .omoBackup,
            defaultFilename: backupViewModel.exportFilename
        ) { result in
            backupViewModel.handleExportCompletion(result)
        }
        .fileImporter(
            isPresented: $backupViewModel.isShowingImporter,
            allowedContentTypes: [.omoBackup, .json]
        ) { result in
            backupViewModel.handleImportSelection(result)
        }
        .alert(
            LocalizationKey.Settings.rescueBackupTitle.localized,
            isPresented: $backupViewModel.isShowingRescueExplanation
        ) {
            Button(LocalizationKey.General.cancel.localized, role: .cancel) {
                backupViewModel.cancelRescueExport()
            }
            Button(LocalizationKey.Settings.rescueBackupConfirm.localized) {
                backupViewModel.confirmRescueExport()
            }
        } message: {
            Text(LocalizationKey.Settings.rescueBackupMessage.localized)
        }
        .alert(
            LocalizationKey.Settings.replaceDataTitle.localized,
            isPresented: $backupViewModel.isShowingReplaceConfirmation
        ) {
            Button(LocalizationKey.General.cancel.localized, role: .cancel) {
                backupViewModel.cancelReplaceImport()
            }
            Button(LocalizationKey.Settings.replaceDataConfirm.localized, role: .destructive) {
                backupViewModel.confirmReplaceImport {
                    await onBackupImported()
                    dismiss()
                }
            }
        } message: {
            Text(LocalizationKey.Settings.replaceDataMessage.localized)
        }
        .errorAlert(
            isPresented: $backupViewModel.showError,
            message: backupViewModel.errorMessage,
            onDismiss: backupViewModel.clearError
        )
        .toast($backupViewModel.toast)
    }
}
