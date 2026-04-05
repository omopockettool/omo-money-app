//
//  EditUserView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import CoreData
import SwiftUI

struct EditUserView: View {
    @StateObject private var viewModel: EditUserViewModel
    @Binding var navigationPath: NavigationPath

    /// ✅ CLEAN ARCHITECTURE: Uses convenience initializer with DI Container
    init(user: UserDomain, context: NSManagedObjectContext, navigationPath: Binding<NavigationPath>) {
        self._viewModel = StateObject(wrappedValue: EditUserViewModel(user: user))
        self._navigationPath = navigationPath
    }

    /// For use in sheets where navigation is not needed
    /// ✅ CLEAN ARCHITECTURE: Uses convenience initializer with DI Container
    init(user: UserDomain, context: NSManagedObjectContext) {
        self._viewModel = StateObject(wrappedValue: EditUserViewModel(user: user))
        self._navigationPath = .constant(NavigationPath())
    }
    
    var body: some View {
        Form {
            Section(header: Text("User Information")) {
                TextField("Name (Optional)", text: $viewModel.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .formFocusAnimation()
                
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .formFocusAnimation()
            }
            
            Section(header: Text("User Details")) {
                HStack {
                    Text("Created")
                    Spacer()
                    Text(DateFormatterHelper.formatDate(viewModel.userCreatedAt))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Last Modified")
                    Spacer()
                    Text(DateFormatterHelper.formatDate(viewModel.userLastModifiedAt))
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button("Update User") {
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
        .navigationTitle("Edit User")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
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
    let context = PersistenceController.preview.container.viewContext
    let user = UserDomain(
        id: UUID(),
        name: "John Doe",
        email: "john@example.com",
        createdAt: Date(),
        lastModifiedAt: Date()
    )

    NavigationStack {
        EditUserView(
            user: user,
            context: context,
            navigationPath: .constant(NavigationPath())
        )
    }
}
