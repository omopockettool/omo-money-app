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
    
    init(user: User, context: NSManagedObjectContext, navigationPath: Binding<NavigationPath>) {
        let userService = UserService(context: context)
        self._viewModel = StateObject(wrappedValue: EditUserViewModel(user: user, userService: userService))
        self._navigationPath = navigationPath
    }
    
    // For use in sheets where navigation is not needed
    init(user: User, context: NSManagedObjectContext) {
        let userService = UserService(context: context)
        self._viewModel = StateObject(wrappedValue: EditUserViewModel(user: user, userService: userService))
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
    let user = User(context: context)
    user.id = UUID()
    user.name = "John Doe"
    user.email = "john@example.com"
    user.createdAt = Date()
    user.lastModifiedAt = Date()
    
    return NavigationStack {
        EditUserView(
            user: user,
            context: context,
            navigationPath: .constant(NavigationPath())
        )
    }
}
