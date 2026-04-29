//
//  EditUserView.swift
//  OMOMoney
//

import SwiftUI
import SwiftData

struct EditUserView: View {
    @State private var viewModel: EditUserViewModel
    @Binding var navigationPath: NavigationPath

    init(user: SDUser, navigationPath: Binding<NavigationPath>) {
        self._viewModel = State(wrappedValue: EditUserViewModel(user: user))
        self._navigationPath = navigationPath
    }

    /// For use in sheets where navigation is not needed
    init(user: SDUser) {
        self._viewModel = State(wrappedValue: EditUserViewModel(user: user))
        self._navigationPath = .constant(NavigationPath())
    }

    var body: some View {
        Form {
            Section(header: Text(LocalizationKey.User.info.localized)) {
                TextField(LocalizationKey.User.namePlaceholder.localized, text: $viewModel.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .formFocusAnimation()

                TextField(LocalizationKey.User.emailPlaceholder.localized, text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .formFocusAnimation()
            }

            Section(header: Text(LocalizationKey.User.details.localized)) {
                HStack {
                    Text(LocalizationKey.User.createdAt.localized)
                    Spacer()
                    Text(DateFormatterHelper.formatDate(viewModel.userCreatedAt))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(LocalizationKey.User.updatedAt.localized)
                    Spacer()
                    Text(DateFormatterHelper.formatDate(viewModel.userLastModifiedAt))
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button(LocalizationKey.User.edit.localized) {
                    Task {
                        await viewModel.updateUser()
                    }
                }
                .frame(maxWidth: .infinity)
                .disabled(viewModel.name.isEmpty)
                .buttonPressAnimation()
                .scaleEffect(viewModel.name.isEmpty ? 0.95 : 1.0)
                .animation(AnimationHelper.buttonState, value: viewModel.name.isEmpty)
            }
        }
        .navigationTitle(LocalizationKey.User.edit.localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(LocalizationKey.General.cancel.localized) {
                    withAnimation(AnimationHelper.slide) {
                        navigationPath.removeLast()
                    }
                }
                .buttonPressAnimation()
            }
        }
        .onChange(of: viewModel.shouldNavigateBack) { _, shouldNavigate in
            if shouldNavigate {
                withAnimation(AnimationHelper.smoothEase) {
                    navigationPath.removeLast()
                }
                viewModel.resetForm()
            }
        }
        .animation(AnimationHelper.smoothSpring, value: viewModel.isLoading)
    }
}

#Preview {
    let user = SDUser.mock(name: "John Doe", email: "john@example.com")
    NavigationStack {
        EditUserView(user: user, navigationPath: .constant(NavigationPath()))
    }
    .modelContainer(ModelContainer.preview)
}
