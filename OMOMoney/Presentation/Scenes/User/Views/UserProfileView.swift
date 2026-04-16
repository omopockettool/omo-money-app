import SwiftUI

struct UserProfileView: View {
    let user: SDUser
    let onUserUpdated: (SDUser) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var nameFocused: Bool?

    private let updateUserUseCase = AppDIContainer.shared.makeUpdateUserUseCase()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 72, height: 72)
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .animation(AnimationHelper.quickSpring, value: name)

                // Name field
                LimitedTextField(
                    icon: "person.fill",
                    placeholder: "Nombre",
                    text: $name,
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

                if let error = errorMessage {
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
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
        }
        .onAppear { name = user.name; nameFocused = true }
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        user.name = trimmed
        user.lastModifiedAt = Date()
        do {
            try await updateUserUseCase.execute(user: user)
            onUserUpdated(user)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
