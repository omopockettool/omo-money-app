//
//  AddUserView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import CoreData
import SwiftUI

struct AddUserView: View {
    @StateObject private var viewModel: CreateUserViewModel
    @Binding var navigationPath: NavigationPath
    
    @State private var name = ""
    @State private var email = ""
    
    init(context: NSManagedObjectContext, navigationPath: Binding<NavigationPath>) {
        let userService = UserService(context: context)
        self._viewModel = StateObject(wrappedValue: CreateUserViewModel(userService: userService))
        self._navigationPath = navigationPath
    }
    
    // For use in sheets where navigation is not needed
    init(context: NSManagedObjectContext) {
        let userService = UserService(context: context)
        self._viewModel = StateObject(wrappedValue: CreateUserViewModel(userService: userService))
        self._navigationPath = .constant(NavigationPath())
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // User Information
            VStack(alignment: .leading, spacing: 12) {
                Text("User Information")
                    .font(.headline)
                
                TextField("Name (Optional)", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .formFocusAnimation()
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(.horizontal)
                    .formFocusAnimation()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .transition(.opacity.combined(with: .scale))
            .animation(AnimationHelper.gentleEase, value: name.isEmpty)
            
            // Add Button
            Button("Add User") {
                addUser()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(email.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(email.isEmpty)
            .buttonPressAnimation()
            .scaleEffect(email.isEmpty ? 0.95 : 1.0)
            .animation(AnimationHelper.buttonState, value: email.isEmpty)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Add User")
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
    
    private func addUser() {
        viewModel.name = name
        viewModel.email = email
        
        Task {
            await viewModel.createUser()
        }
    }
}

#Preview {
    NavigationStack {
        AddUserView(
            context: PersistenceController.preview.container.viewContext,
            navigationPath: .constant(NavigationPath())
        )
    }
}
