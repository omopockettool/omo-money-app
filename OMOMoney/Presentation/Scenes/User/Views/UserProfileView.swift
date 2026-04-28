import SwiftUI

struct UserProfileView: View {
    let user: SDUser
    let onUserUpdated: (SDUser) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: UserProfileViewModel
    @FocusState private var nameFocused: Bool?

    init(user: SDUser, onUserUpdated: @escaping (SDUser) -> Void) {
        self.user = user
        self.onUserUpdated = onUserUpdated
        _viewModel = State(wrappedValue: UserProfileViewModel(user: user))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Text(String(viewModel.name.prefix(1)).uppercased())
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .animation(AnimationHelper.quickSpring, value: viewModel.name)

                // Name field
                LimitedTextField(
                    icon: "person.fill",
                    placeholder: "Nombre",
                    text: $viewModel.name,
                    maxLength: 40,
                    focusedField: $nameFocused,
                    fieldValue: true
                )

                // Email (read-only)
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(AppConstants.UserInterface.padding)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(AppConstants.UserInterface.padding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task { await save() }
                }
                .disabled(!viewModel.canSave)
            }
        }
    }

    private func save() async {
        if let updatedUser = await viewModel.save() {
            onUserUpdated(updatedUser)
            dismiss()
        }
    }
}
