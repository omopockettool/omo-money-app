//
//  EditUserView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI

struct EditUserView: View {
    @ObservedObject var viewModel: UserViewModel
    @ObservedObject var groupViewModel: GroupViewModel
    @ObservedObject var userGroupViewModel: UserGroupViewModel
    let user: User
    @Binding var navigationPath: NavigationPath
    
    @State private var name: String
    @State private var email: String
    
    init(viewModel: UserViewModel, groupViewModel: GroupViewModel, userGroupViewModel: UserGroupViewModel, user: User, navigationPath: Binding<NavigationPath>) {
        self.viewModel = viewModel
        self.groupViewModel = groupViewModel
        self.userGroupViewModel = userGroupViewModel
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
                    Text("\(user.safeUserGroupsCount)")
                        .foregroundColor(.secondary)
                }
                
                // Check if user is owner in any group
                if user.hasOwnerRole {
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
            
            Section(header: Text("Group Management")) {
                Button("Create Group") {
                    createGroup()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
                
                HStack {
                    Button("Refresh Data") {
                        refreshData()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.green)
                    
                    Button("Debug Data Persistence") {
                        debugDataPersistence()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.orange)
                }
                
                Button("Test Group Creation Flow") {
                    testGroupCreationFlow()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.purple)
            }
            
            Section {
                Button("Delete User", role: .destructive) {
                    deleteUser()
                }
                .frame(maxWidth: .infinity)
                .disabled(user.hasGroups)
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
    
    private func createGroup() {
        navigationPath.append(CreateGroupDestination(user: user))
    }
    
    private func refreshData() {
        print("🔄 === REFRESHING DATA ===")
        print("📅 Timestamp: \(Date())")
        
        // Refresh all ViewModels to get latest data
        userGroupViewModel.fetchUserGroups()
        groupViewModel.fetchGroups()
        viewModel.fetchUsers()
        
        print("✅ Data refreshed successfully")
        print("📊 Current counts:")
        print("  - UserGroups: \(userGroupViewModel.userGroups.count)")
        print("  - Groups: \(groupViewModel.groups.count)")
        print("  - Users: \(viewModel.users.count)")
        print("🔄 === END REFRESHING DATA ===\n")
    }
    
    private func testGroupCreationFlow() {
        print("🧪 === TESTING GROUP CREATION FLOW ===")
        print("📅 Timestamp: \(Date())")
        
        // Step 1: Check current state
        print("\n📊 Step 1: Current State")
        print("Current user: \(user.name ?? "N/A") (\(user.email ?? "N/A"))")
        print("Current groups count: \(groupViewModel.groups.count)")
        print("Current userGroups count: \(userGroupViewModel.userGroups.count)")
        
        // Step 2: Create a test group
        print("\n🏗️ Step 2: Creating Test Group")
        let testGroupName = "Test Group \(Date().timeIntervalSince1970)"
        groupViewModel.createGroup(name: testGroupName, currency: "USD")
        print("🔄 Test group creation initiated (async operation)")
        
        // Step 3: Create UserGroup relationship (will be done after group creation)
        print("\n🔗 Step 3: Creating UserGroup Relationship")
        print("🔄 UserGroup relationship creation will be initiated after group creation completes")
        
        // Wait a bit for async operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refreshData()
            self.verifyTestGroupCreation()
        }
        
        // Step 4: Refresh data and verify
        print("\n🔄 Step 4: Refreshing and Verifying Data")
        refreshData()
        
        // Step 5: Final verification
        print("\n✅ Step 5: Final Verification")
        print("Final groups count: \(groupViewModel.groups.count)")
        print("Final userGroups count: \(userGroupViewModel.userGroups.count)")
        
        // Check if the test group exists
        if let testGroup = groupViewModel.groups.first(where: { $0.name?.contains("Test Group") == true }) {
            print("Test group found:")
            print("  - Name: \(testGroup.name ?? "N/A")")
            print("  - UserGroups: \(testGroup.userGroups?.count ?? 0)")
            
            // Show users in test group through UserGroup relationship
            if let userGroups = testGroup.userGroups?.allObjects as? [UserGroup] {
                print("  - Users in Test Group:")
                for userGroup in userGroups {
                    if let user = userGroup.user {
                        print("    - \(user.name ?? "N/A") (\(user.email ?? "N/A")) - Role: \(userGroup.role ?? "N/A")")
                    }
                }
            }
        }
        
        // Check if the UserGroup relationship exists
        let userUserGroups = userGroupViewModel.userGroups(for: user)
        print("User's UserGroups: \(userUserGroups.count)")
        for userGroup in userUserGroups {
            print("  - Group: \(userGroup.group?.name ?? "N/A") - Role: \(userGroup.role ?? "N/A")")
        }
        
        print("🧪 === END TESTING GROUP CREATION FLOW ===\n")
    }
    
    private func verifyTestGroupCreation() {
        print("🔍 === VERIFYING TEST GROUP CREATION ===")
        print("📅 Timestamp: \(Date())")
        
        // Check if the test group exists
        if let testGroup = groupViewModel.groups.first(where: { $0.name?.contains("Test Group") == true }) {
            print("✅ Test group found:")
            print("  - Name: \(testGroup.name ?? "N/A")")
            print("  - UserGroups: \(testGroup.userGroups?.count ?? 0)")
            
            // Show users in test group through UserGroup relationship
            if let userGroups = testGroup.userGroups?.allObjects as? [UserGroup] {
                print("  - Users in Test Group:")
                for userGroup in userGroups {
                    if let user = userGroup.user {
                        print("    - \(user.name ?? "N/A") (\(user.email ?? "N/A")) - Role: \(userGroup.role ?? "N/A")")
                    }
                }
            }
            
            // Create UserGroup relationship if it doesn't exist
            let existingUserGroup = userGroupViewModel.userGroups.first { userGroup in
                userGroup.group?.id == testGroup.id && userGroup.user?.id == user.id
            }
            
            if existingUserGroup == nil {
                print("🔄 Creating UserGroup relationship for test group...")
                userGroupViewModel.createUserGroup(user: user, group: testGroup, role: "owner")
                
                // Wait a bit more and refresh
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.refreshData()
                    self.finalVerification()
                }
            } else {
                print("✅ UserGroup relationship already exists")
                finalVerification()
            }
        } else {
            print("❌ Test group not found yet")
        }
        
        print("🔍 === END VERIFYING TEST GROUP CREATION ===\n")
    }
    
    private func finalVerification() {
        print("✅ === FINAL VERIFICATION ===")
        print("📅 Timestamp: \(Date())")
        
        // Final verification
        print("Final groups count: \(groupViewModel.groups.count)")
        print("Final userGroups count: \(userGroupViewModel.userGroups.count)")
        
        // Check if the test group exists
        if let testGroup = groupViewModel.groups.first(where: { $0.name?.contains("Test Group") == true }) {
            print("Test group found:")
            print("  - Name: \(testGroup.name ?? "N/A")")
            print("  - UserGroups: \(testGroup.userGroups?.count ?? 0)")
            
            // Show users in test group through UserGroup relationship
            if let userGroups = testGroup.userGroups?.allObjects as? [UserGroup] {
                print("  - Users in Test Group:")
                for userGroup in userGroups {
                    if let user = userGroup.user {
                        print("    - \(user.name ?? "N/A") (\(user.email ?? "N/A")) - Role: \(userGroup.role ?? "N/A")")
                    }
                }
            }
        }
        
        // Check if the UserGroup relationship exists
        let userUserGroups = userGroupViewModel.userGroups(for: user)
        print("User's UserGroups: \(userUserGroups.count)")
        for userGroup in userUserGroups {
            print("  - Group: \(userGroup.group?.name ?? "N/A") - Role: \(userGroup.role ?? "N/A")")
        }
        
        print("✅ === END FINAL VERIFICATION ===\n")
    }
    
    private func debugDataPersistence() {
        print("🔍 === DEBUG DATA PERSISTENCE ===")
        print("📅 Timestamp: \(Date())")
        
        // Debug User Data
        print("\n👤 === USER DATA ===")
        print("User ID: \(user.id?.uuidString ?? "N/A")")
        print("User Name: \(user.name ?? "N/A")")
        print("User Email: \(user.email ?? "N/A")")
        print("Created At: \(formatDate(user.createdAt))")
        print("Last Modified: \(formatDate(user.lastModifiedAt))")
        print("User Groups Count: \(user.userGroups?.count ?? 0)")
        print("Has Owner Role: \(user.hasOwnerRole ? "✅ Yes" : "❌ No")")
        
        // Debug UserGroup Relationships
        print("\n🔗 === USERGROUP RELATIONSHIPS ===")
        if let userGroups = user.userGroups?.allObjects as? [UserGroup] {
            print("Total UserGroup relationships: \(userGroups.count)")
            for (index, userGroup) in userGroups.enumerated() {
                print("  [\(index + 1)] UserGroup ID: \(userGroup.id?.uuidString ?? "N/A")")
                print("      Role: \(userGroup.role ?? "N/A")")
                print("      Joined At: \(formatDate(userGroup.joinedAt))")
                if let group = userGroup.group {
                    print("      Group: \(group.name ?? "N/A") (ID: \(group.id?.uuidString ?? "N/A"))")
                }
            }
        } else {
            print("No UserGroup relationships found")
        }
        
        // Debug UserGroup ViewModel
        print("\n📊 === USERGROUP VIEWMODEL ===")
        print("UserGroup ViewModel Count: \(userGroupViewModel.userGroups.count)")
        print("UserGroup ViewModel Data:")
        for (index, userGroup) in userGroupViewModel.userGroups.enumerated() {
            print("  [\(index + 1)] UserGroup ID: \(userGroup.id?.uuidString ?? "N/A")")
            print("      Role: \(userGroup.role ?? "N/A")")
            print("      Joined At: \(formatDate(userGroup.joinedAt))")
            if let group = userGroup.group {
                print("      Group: \(group.name ?? "N/A") (ID: \(group.id?.uuidString ?? "N/A"))")
            }
            if let user = userGroup.user {
                print("      User: \(user.name ?? "N/A") (ID: \(user.id?.uuidString ?? "N/A"))")
            }
        }
        
        // Debug Group ViewModel
        print("\n🏠 === GROUP VIEWMODEL ===")
        print("Total Groups: \(groupViewModel.groups.count)")
        for (index, group) in groupViewModel.groups.enumerated() {
            print("  [\(index + 1)] Group ID: \(group.id?.uuidString ?? "N/A")")
            print("      Name: \(group.name ?? "N/A")")
            print("      Currency: \(group.currency ?? "N/A")")
            print("      Created At: \(formatDate(group.createdAt))")
            print("      Last Modified: \(formatDate(group.lastModifiedAt))")
            print("      UserGroups Count: \(group.userGroups?.count ?? 0)")
            
            // Show users in this group through UserGroup relationship
            if let userGroups = group.userGroups?.allObjects as? [UserGroup] {
                print("      Users in Group (via UserGroup):")
                for userGroup in userGroups {
                    if let user = userGroup.user {
                        print("        - \(user.name ?? "N/A") (\(user.email ?? "N/A")) - Role: \(userGroup.role ?? "N/A")")
                    }
                }
            }
        }
        
        // Debug Core Data Context
        print("\n💾 === CORE DATA CONTEXT ===")
        print("Context has changes: \(user.managedObjectContext?.hasChanges ?? false)")
        
        // Check for any save errors
        if let context = user.managedObjectContext {
            print("Context: \(context)")
            print("Context has changes: \(context.hasChanges)")
            
            // Check if there are any pending changes
            if context.hasChanges {
                print("⚠️ Context has unsaved changes")
            }
            
            // Check if context is valid
            print("Context is valid: \(context.persistentStoreCoordinator != nil)")
        }
        
        // Check ViewModel error states
        print("\n⚠️ === ERROR STATES ===")
        if let userError = viewModel.errorMessage {
            print("UserViewModel Error: \(userError)")
        }
        if let groupError = groupViewModel.errorMessage {
            print("GroupViewModel Error: \(groupError)")
        }
        if let userGroupError = userGroupViewModel.errorMessage {
            print("UserGroupViewModel Error: \(userGroupError)")
        }
        
        // Debug UserGroup ViewModel specific data for current user
        print("\n🎯 === CURRENT USER SPECIFIC DATA ===")
        let userSpecificUserGroups = userGroupViewModel.userGroups(for: user)
        print("UserGroup ViewModel - Groups for current user: \(userSpecificUserGroups.count)")
        for userGroup in userSpecificUserGroups {
            print("  Group: \(userGroup.group?.name ?? "N/A") - Role: \(userGroup.role ?? "N/A")")
        }
        
        let userSpecificGroups = userGroupViewModel.groups(for: user)
        print("UserGroup ViewModel - Groups for current user: \(userSpecificGroups.count)")
        for group in userSpecificGroups {
            print("  Group: \(group.name ?? "N/A") - Currency: \(group.currency ?? "N/A")")
        }
        
        print("\n🔍 === END DEBUG DATA PERSISTENCE ===")
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
            viewModel: UserViewModel(context: context),
            groupViewModel: GroupViewModel(context: context),
            userGroupViewModel: UserGroupViewModel(context: context),
            user: user,
            navigationPath: .constant(NavigationPath())
        )
    }
}
