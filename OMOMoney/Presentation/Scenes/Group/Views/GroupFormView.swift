import SwiftUI

struct GroupFormView: View {
    let group: SDGroup
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingGroupInfoEditor = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: Información del grupo
                groupSection

                // MARK: Contenido del grupo
                contentSection
            }
            .padding(AppConstants.UserInterface.padding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Ajustes del grupo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .sheet(isPresented: $showingGroupInfoEditor) {
            GroupInfoEditSheet(group: group) {
                onSaved()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var groupSection: some View {
        GroupSettingsSection(title: "Grupo") {
            Button {
                showingGroupInfoEditor = true
            } label: {
                GroupSettingsRow(
                    icon: "person.2.fill",
                    color: .accentColor,
                    title: group.name,
                    subtitle: group.currency
                )
                .padding(AppConstants.UserInterface.padding)
            }
            .buttonStyle(.plain)
        }
    }

    private var contentSection: some View {
        GroupSettingsSection(title: "Contenido") {
            NavigationLink {
                CategoryManagementView(group: group)
            } label: {
                GroupSettingsRow(
                    icon: "tag.fill",
                    color: .orange,
                    title: "Categorías",
                    titleColor: .white
                )
                .padding(AppConstants.UserInterface.padding)
            }

            Divider()
                .padding(.horizontal, AppConstants.UserInterface.padding)

            NavigationLink {
                PaymentMethodManagementView(group: group)
            } label: {
                GroupSettingsRow(
                    icon: "creditcard.fill",
                    color: .blue,
                    title: "Métodos de pago",
                    titleColor: .white
                )
                .padding(AppConstants.UserInterface.padding)
            }
        }
    }
}

private struct GroupSettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        }
    }
}

private struct GroupSettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    var subtitle: String?
    var titleColor: Color = .primary

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(titleColor)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
    }
}
