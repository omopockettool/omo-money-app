//
//  CreateGroupView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI

struct CreateGroupView: View {
    @ObservedObject var groupViewModel: GroupViewModel
    @ObservedObject var userGroupViewModel: UserGroupViewModel
    let user: User
    @Binding var navigationPath: NavigationPath
    
    @State private var groupName: String = ""
    @State private var currency: String = "USD"
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let availableCurrencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "MXN", "BRL"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Group Information
            VStack(alignment: .leading, spacing: 12) {
                Text("Group Information")
                    .font(.headline)
                
                TextField("Group Name", text: $groupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Picker("Currency", selection: $currency) {
                    ForEach(availableCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Group Details
            VStack(alignment: .leading, spacing: 12) {
                Text("Group Details")
                    .font(.headline)
                
                HStack {
                    Text("Owner")
                    Spacer()
                    Text(user.name ?? user.email ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Default Role")
                    Spacer()
                    Label("Owner", systemImage: "crown.fill")
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color(.systemRed).opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Create Button
            Button(action: createGroup) {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Creating Group...")
                    }
                } else {
                    Text("Create Group")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(groupName.isEmpty || isLoading ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(groupName.isEmpty || isLoading)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Create Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    navigationPath.removeLast()
                }
            }
        }
        .onAppear {
            clearError()
        }
    }
    
    private func createGroup() {
        guard !groupName.isEmpty else { return }
        
        isLoading = true
        clearError()
        
        // Create group in background
        Task {
            await createGroupInBackground()
        }
    }
    
    @MainActor
    private func createGroupInBackground() async {
        // Create the group (now async)
        groupViewModel.createGroup(name: groupName, currency: currency)
        
        // Wait a bit for the group creation to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Check if group was created successfully
        if let errorMessage = groupViewModel.errorMessage {
            self.errorMessage = errorMessage
            isLoading = false
            return
        }
        
        // Find the newly created group
        guard let newGroup = groupViewModel.groups.first(where: { $0.name == groupName }) else {
            errorMessage = "Group created but not found in list"
            isLoading = false
            return
        }
        
        // Create the user-group relationship with owner role (now async)
        userGroupViewModel.createUserGroup(user: user, group: newGroup, role: "owner")
        
        // Wait a bit more for the user-group relationship to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Check if user-group relationship was created successfully
        if let errorMessage = userGroupViewModel.errorMessage {
            self.errorMessage = errorMessage
            isLoading = false
            return
        }
        
        // Success - navigate back
        isLoading = false
        navigationPath.removeLast()
    }
    
    private func clearError() {
        errorMessage = nil
        groupViewModel.clearError()
        userGroupViewModel.clearError()
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
        
        return CreateGroupView(
            groupViewModel: GroupViewModel(context: context),
            userGroupViewModel: UserGroupViewModel(context: context),
            user: user,
            navigationPath: .constant(NavigationPath())
        )
    }
}
