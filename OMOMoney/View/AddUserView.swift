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
