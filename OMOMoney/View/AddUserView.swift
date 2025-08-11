//
//  AddUserView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI

struct AddUserView: View {
    @ObservedObject var viewModel: UserViewModel
    @Binding var navigationPath: NavigationPath
    
    @State private var name = ""
    @State private var email = ""
    
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
            
            Section {
                Button("Add User") {
                    addUser()
                }
                .frame(maxWidth: .infinity)
                .disabled(email.isEmpty)
            }
        }
        .navigationTitle("Add User")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    navigationPath.removeLast()
                }
            }
        }
    }
    
    private func addUser() {
        if viewModel.createUser(name: name, email: email) {
            navigationPath.removeLast()
        }
    }
}

#Preview {
    NavigationStack {
        AddUserView(
            viewModel: UserViewModel(context: PersistenceController.preview.container.viewContext),
            navigationPath: .constant(NavigationPath())
        )
    }
}
