//
//  AppContentView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 13/9/25.
//

import CoreData
import SwiftUI

struct AppContentView: View {
    @State private var navigationPath = NavigationPath()
    @State private var selectedUser: User?
    @State private var selectedGroup: Group?
    @State private var isLoading = true
    
    private let context: NSManagedObjectContext
    private let userService: UserService
    private let groupService: GroupService
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.userService = UserService(context: context)
        self.groupService = GroupService(context: context)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            if isLoading {
                loadingView
            } else if let user = selectedUser, let group = selectedGroup {
                mainContentView(user: user, group: group)
            } else {
                setupRequiredView
            }
        }
        .navigationTitle("OMOMoney")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadInitialData()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your data...")
                .font(.headline)
                .padding(.top)
        }
    }
    
    // MARK: - Setup Required View
    private var setupRequiredView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Setup Required")
                .font(.title)
            
            Text("Please create a user and group to continue")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Go to Settings") {
                // TODO: Navigate to settings or user management
                print("Navigate to settings")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Main Content View
    private func mainContentView(user: User, group: Group) -> some View {
        VStack {
            // Header with user and group info
            headerView(user: user, group: group)
            
            // Main content area
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "chart.bar.fill")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                
                Text("Welcome back, \(user.name ?? "User")")
                    .font(.title2)
                
                Text("Group: \(group.name ?? "Group")")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Your expense tracking dashboard will be here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Quick action buttons
            quickActionsView()
        }
        .padding()
    }
    
    // MARK: - Header View
    private func headerView(user: User, group: Group) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(user.name ?? "User")
                    .font(.headline)
                Text(group.name ?? "Group")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // TODO: Navigate to settings
                print("Settings tapped")
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
    
    // MARK: - Quick Actions View
    private func quickActionsView() -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                quickActionButton(
                    title: "Add Expense",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    print("Add expense tapped")
                }
                
                quickActionButton(
                    title: "View Reports",
                    icon: "chart.pie.fill",
                    color: .blue
                ) {
                    print("View reports tapped")
                }
            }
            
            HStack(spacing: 16) {
                quickActionButton(
                    title: "Manage Groups",
                    icon: "person.3.fill",
                    color: .orange
                ) {
                    print("Manage groups tapped")
                }
                
                quickActionButton(
                    title: "Categories",
                    icon: "tag.fill",
                    color: .purple
                ) {
                    print("Categories tapped")
                }
            }
        }
        .padding()
    }
    
    private func quickActionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helper Functions
extension AppContentView {
    @MainActor
    private func loadInitialData() {
        Task {
            isLoading = true
            
            do {
                // Load users
                let users = try await userService.fetchUsers()
                guard let firstUser = users.first else {
                    print("❌ AppContentView: No users found")
                    isLoading = false
                    return
                }
                
                // Load groups for the first user
                let groups = try await groupService.fetchGroups()
                let userGroups = groups.filter { group in
                    // Check if user is member of this group
                    group.userGroups?.contains { userGroup in
                        (userGroup as? UserGroup)?.user == firstUser
                    } ?? false
                }
                
                await MainActor.run {
                    selectedUser = firstUser
                    selectedGroup = userGroups.first
                    isLoading = false
                }
                
                print("✅ AppContentView: Loaded user: \(firstUser.name ?? "Unknown"), groups: \(userGroups.count)")
                
            } catch {
                print("❌ AppContentView: Error loading data: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AppContentView(context: PersistenceController.preview.container.viewContext)
}