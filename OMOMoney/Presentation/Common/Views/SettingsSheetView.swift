import SwiftUI

struct SettingsSheetView: View {
    let user: SDUser
    let onUserUpdated: (SDUser) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Cuenta") {
                    NavigationLink {
                        UserProfileView(user: user, onUserUpdated: onUserUpdated)
                    } label: {
                        settingsRow(icon: "person.fill", color: .purple, title: user.name)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Ajustes")
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
