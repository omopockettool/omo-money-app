//
//  AddUserView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI

struct AddUserView: View {
    @ObservedObject var viewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
    
    private func addUser() {
        guard !email.isEmpty else {
            alertMessage = "Email is required"
            showingAlert = true
            return
        }
        
        if let _ = viewModel.createUser(name: name, email: email) {
            dismiss()
        } else {
            // Error is already handled by the ViewModel and shown in the main view
            // We just need to wait a bit for the error to be processed
        }
    }
}

#Preview {
    AddUserView(viewModel: UserViewModel(context: PersistenceController.preview.container.viewContext))
}
