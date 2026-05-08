import SwiftUI

struct SettingsSheetView: View {
    let user: SDUser
    let onUserUpdated: (SDUser) -> Void
    let onBackupImported: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var backupViewModel: SettingsBackupViewModel

    @MainActor
    init(
        user: SDUser,
        onUserUpdated: @escaping (SDUser) -> Void,
        onBackupImported: @escaping () async -> Void,
        container: AppDIContainer = .shared
    ) {
        self.user = user
        self.onUserUpdated = onUserUpdated
        self.onBackupImported = onBackupImported
        _backupViewModel = State(wrappedValue: container.makeSettingsBackupViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                Section(LocalizationKey.Settings.account.localized) {
                    NavigationLink {
                        UserProfileView(user: user, onUserUpdated: onUserUpdated)
                    } label: {
                        settingsRow(icon: "person.fill", color: .purple, title: user.name)
                    }
                }

                Section(LocalizationKey.Settings.backup.localized) {
                    Text(LocalizationKey.Settings.backupDescription.localized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        backupViewModel.beginManualExport()
                    } label: {
                        settingsRow(
                            icon: "square.and.arrow.up",
                            color: .green,
                            title: LocalizationKey.Settings.exportBackup.localized
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        backupViewModel.beginImport()
                    } label: {
                        settingsRow(
                            icon: "square.and.arrow.down",
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
                        settingsRow(icon: "info.circle.fill", color: .blue, title: LocalizationKey.Settings.aboutOMO.localized)
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
                        settingsRow(
                            icon: "person.badge.plus",
                            color: .orange,
                            title: "Onboarding Preview"
                        )
                    }
                }
#endif
            }
            .listStyle(.insetGrouped)
            .navigationTitle(LocalizationKey.Settings.title.localized)
            .navigationBarTitleDisplayMode(.inline)
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
        .alert(
            LocalizationKey.General.error.localized,
            isPresented: Binding(
                get: { backupViewModel.errorMessage != nil },
                set: { if !$0 { backupViewModel.errorMessage = nil } }
            )
        ) {
            Button(LocalizationKey.General.ok.localized, role: .cancel) {
                backupViewModel.errorMessage = nil
            }
        } message: {
            Text(backupViewModel.errorMessage ?? "")
        }
        .toast($backupViewModel.toast)
    }

    private func settingsRow(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
