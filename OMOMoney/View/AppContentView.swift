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
                // Use the new DashboardView
                DashboardView(context: context)
                    .navigationBarHidden(true)
            } else {
                setupRequiredView
            }
        }
        .navigationTitle("OMOMoney")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark) // Apply dark mode for prototype design
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
    
    // MARK: - Main Content View (Legacy - Now using DashboardView)
    // This content has been moved to DashboardView for better modularization
    
    // MARK: - Legacy Views (Moved to DashboardView)
    // Header and Quick Actions have been moved to DashboardView components
}

// MARK: - Helper Functions
extension AppContentView {
    @MainActor
    private func loadInitialData() {
        Task {
            isLoading = true
            
            do {
                // Get the current user
                guard let currentUser = try await userService.getCurrentUser() else {
                    print("❌ AppContentView: No users found")
                    isLoading = false
                    return
                }
                
                // Load groups for the current user
                let userGroupService = UserGroupService(context: context)
                let userGroups = try await userGroupService.getGroups(for: currentUser)
                
                await MainActor.run {
                    selectedUser = currentUser
                    selectedGroup = userGroups.first
                    isLoading = false
                }
                
                print("✅ AppContentView: Loaded user: \(currentUser.name ?? "Unknown"), groups: \(userGroups.count)")
                
            } catch {
                print("❌ AppContentView: Error loading data: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Debug function moved to DashboardView
    // Debug functionality is now accessible through the dashboard header
}

#Preview {
    AppContentView(context: PersistenceController.preview.container.viewContext)
}