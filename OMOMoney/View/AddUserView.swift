//
//  AddUserView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI
import CoreData

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
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
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
            
            Spacer()
        }
        .padding()
        .navigationTitle("Add User")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    navigationPath.removeLast()
                }
            }
        }
        .onChange(of: viewModel.shouldNavigateBack) { oldValue, shouldNavigate in
            if shouldNavigate {
                navigationPath.removeLast()
                viewModel.resetForm()
            }
        }
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
