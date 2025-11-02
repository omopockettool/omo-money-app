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
            
            // Debug button for logging all entities
            Button(action: {
                Task {
                    await logAllEntities()
                }
            }) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title2)
                    Text("Debug: Show All Data")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red)
                .cornerRadius(12)
            }
            .padding(.top, 10)
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
    
    /// Debug function to log all entities in the database
    @MainActor
    private func logAllEntities() async {
        print("\n🔍 =========================")
        print("🔍 DEBUG: Logging all entities")
        print("🔍 =========================")
        
        do {
            // 1. Log current user
            if let currentUser = try await userService.getCurrentUser() {
                print("\n👤 USUARIO:")
                print("   ID: \(currentUser.id?.uuidString ?? "N/A")")
                print("   Nombre: \(currentUser.name ?? "N/A")")
                print("   Email: \(currentUser.email ?? "N/A")")
                print("   Creado: \(currentUser.createdAt ?? Date())")
                
                // 2. Log user's groups
                let userGroupService = UserGroupService(context: context)
                let userGroups = try await userGroupService.getGroups(for: currentUser)
                
                print("\n🏢 GRUPOS (\(userGroups.count)):")
                for (index, group) in userGroups.enumerated() {
                    print("   \(index + 1). ID: \(group.id?.uuidString ?? "N/A")")
                    print("      Nombre: \(group.name ?? "N/A")")
                    print("      Moneda: \(group.currency ?? "N/A")")
                    print("      Creado: \(group.createdAt ?? Date())")
                    
                    // 3. Log categories for each group
                    let categoryService = CategoryService(context: context)
                    let categories = try await categoryService.getCategories(for: group)
                    
                    print("      📁 CATEGORÍAS (\(categories.count)):")
                    for (catIndex, category) in categories.enumerated() {
                        print("         \(catIndex + 1). ID: \(category.id?.uuidString ?? "N/A")")
                        print("            Nombre: \(category.name ?? "N/A")")
                        print("            Color: \(category.color ?? "N/A")")
                        print("            Creado: \(category.createdAt ?? Date())")
                    }
                    print("")
                }
                
            } else {
                print("\n❌ No se encontró usuario actual")
            }
            
        } catch {
            print("\n❌ ERROR logging entities: \(error.localizedDescription)")
        }
        
        print("🔍 =========================\n")
    }
}

#Preview {
    AppContentView(context: PersistenceController.preview.container.viewContext)
}