//
//  CreateGroupView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI

struct CreateGroupView: View {
    @ObservedObject var detailedGroupViewModel: DetailedGroupViewModel
    let user: User
    @Binding var navigationPath: NavigationPath
    
    @State private var groupName: String = ""
    @State private var currency: String = "USD"
    
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
            if let errorMessage = detailedGroupViewModel.groupCreationError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color(.systemRed).opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Create Button
            Button(action: createGroup) {
                if detailedGroupViewModel.isCreatingGroup {
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
            .background(groupName.isEmpty || detailedGroupViewModel.isCreatingGroup ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(groupName.isEmpty || detailedGroupViewModel.isCreatingGroup)
            .onTapGesture {
                // Additional safety check
                if !groupName.isEmpty && !detailedGroupViewModel.isCreatingGroup {
                    createGroup()
                }
            }
            
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
        .onChange(of: detailedGroupViewModel.shouldNavigateBack) { oldValue, shouldNavigate in
            if shouldNavigate {
                // Clear state first to prevent multiple triggers
                detailedGroupViewModel.clearGroupCreationState()
                
                // Navigate back
                navigationPath.removeLast()
            }
        }

    }
    
    private func createGroup() {
        guard !groupName.isEmpty else { return }
        guard !detailedGroupViewModel.isCreatingGroup else { return } // Prevent multiple calls
        
        detailedGroupViewModel.createGroup(name: groupName, currency: currency, user: user)
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
        
        let detailedGroupViewModel = DetailedGroupViewModel(
            userViewModel: UserViewModel(context: context),
            groupViewModel: GroupViewModel(context: context),
            userGroupViewModel: UserGroupViewModel(context: context),
            entryViewModel: EntryViewModel(context: context)
        )
        
        return CreateGroupView(
            detailedGroupViewModel: detailedGroupViewModel,
            user: user,
            navigationPath: .constant(NavigationPath())
        )
    }
}
