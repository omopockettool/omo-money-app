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
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var email: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(viewModel: UserViewModel, user: User) {
        self.viewModel = viewModel
        self.user = user
        self._name = State(initialValue: user.name ?? "")
        self._email = State(initialValue: user.email)
    }
    
    var body: some View {
        NavigationView {
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
                        Text(user.formattedCreatedDate)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Modified")
                        Spacer()
                        Text(user.formattedModifiedDate)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Groups")
                        Spacer()
                        Text("\(user.groupCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    if user.isOwner {
                        HStack {
                            Text("Role")
                            Spacer()
                            Label("Owner", systemImage: "crown.fill")
                                .foregroundColor(.orange)
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
                    .disabled(user.belongsToGroups)
                }
            }
            .navigationTitle("Edit User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func updateUser() {
        guard !email.isEmpty else {
            alertMessage = "Email is required"
            showingAlert = true
            return
        }
        
        if viewModel.updateUser(user, name: name, email: email) {
            dismiss()
        } else {
            // Error is already handled by the ViewModel
        }
    }
    
    private func deleteUser() {
        if viewModel.deleteUser(user) {
            dismiss()
        } else {
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    EditUserView(
        viewModel: UserViewModel(context: context),
        user: User.sampleUser(context: context)
    )
}
