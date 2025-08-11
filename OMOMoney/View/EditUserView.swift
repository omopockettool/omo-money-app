//
//  EditUserView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI

struct EditUserView: View {
    @ObservedObject var viewModel: UserViewModel
    let user: User
    @Binding var navigationPath: NavigationPath
    
    @State private var name: String
    @State private var email: String
    
    init(viewModel: UserViewModel, user: User, navigationPath: Binding<NavigationPath>) {
        self.viewModel = viewModel
        self.user = user
        self._navigationPath = navigationPath
        self._name = State(initialValue: user.name ?? "")
        self._email = State(initialValue: user.email ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("User Information")) {
                TextField("Name (Optional)", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            Section(header: Text("User Details")) {
                HStack {
                    Text("Created")
                    Spacer()
                    Text(formatDate(user.createdAt))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Last Modified")
                    Spacer()
                    Text(formatDate(user.lastModifiedAt))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Groups")
                    Spacer()
                    Text("\(user.userGroups?.count ?? 0)")
                        .foregroundColor(.secondary)
                }
                
                // Check if user is owner in any group
                if let userGroups = user.userGroups {
                    let hasOwnerRole = userGroups.compactMap { $0 as? UserGroup }.contains { userGroup in
                        guard let role = userGroup.role else { return false }
                        return role == "owner"
                    }
                    if hasOwnerRole {
                        HStack {
                            Text("Role")
                            Spacer()
                            Label("Owner", systemImage: "crown.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            Section {
                Button("Update User") {
                    updateUser()
                }
                .frame(maxWidth: .infinity)
                .disabled(email.isEmpty)
            }
            
            Section {
                Button("Delete User", role: .destructive) {
                    deleteUser()
                }
                .frame(maxWidth: .infinity)
                .disabled((user.userGroups?.count ?? 0) > 0)
            }
        }
        .navigationTitle("Edit User")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    navigationPath.removeLast()
                }
            }
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func updateUser() {
        if viewModel.updateUser(user, name: name, email: email) {
            navigationPath.removeLast()
        }
    }
    
    private func deleteUser() {
        if viewModel.deleteUser(user) {
            navigationPath.removeLast()
        }
    }
}

#Preview {
    NavigationStack {
        let context = PersistenceController.preview.container.viewContext
        let user = User(context: context)
        user.id = UUID()
        user.name = "John Doe"
        user.email = "john@example.com"
        user.createdAt = Date()
        user.lastModifiedAt = Date()
        
        return EditUserView(
            viewModel: UserViewModel(context: context),
            user: user,
            navigationPath: .constant(NavigationPath())
        )
    }
}
