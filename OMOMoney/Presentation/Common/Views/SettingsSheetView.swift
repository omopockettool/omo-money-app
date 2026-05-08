import SwiftUI

struct SettingsSheetView: View {
    let user: SDUser
    let onUserUpdated: (SDUser) -> Void

    @Environment(\.dismiss) private var dismiss

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
        }
    }
}
