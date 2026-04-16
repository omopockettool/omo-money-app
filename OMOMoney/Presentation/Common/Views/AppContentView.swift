//
//  AppContentView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 13/9/25.
//

import SwiftUI

struct AppContentView: View {
    @State private var navigationPath = NavigationPath()
    @State private var selectedUser: SDUser?
    @State private var selectedGroup: SDGroup?
    @State private var isLoading = true

    // ✅ Clean Architecture: Use DI Container for dependencies
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let fetchGroupsForUserUseCase: FetchGroupsForUserUseCase

    init() {
        let container = AppDIContainer.shared
        self.getCurrentUserUseCase = container.makeGetCurrentUserUseCase()
        self.fetchGroupsForUserUseCase = container.makeFetchGroupsForUserUseCase()
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            if isLoading {
                loadingView
            } else if let _ = selectedUser, let _ = selectedGroup {
                // ✅ Clean Architecture: No context passed to DashboardView
                DashboardView()
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
        Color(.systemBackground).ignoresSafeArea()
    }
    
    // MARK: - Setup Required View
    private var setupRequiredView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Configuración requerida")
                .font(.title)
            
            Text("Por favor crea un usuario y grupo para continuar")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Ir a Configuración") {
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
                // ✅ Clean Architecture: Use Use Case instead of Service
                guard let currentUser = try await getCurrentUserUseCase.execute() else {
                    print("❌ AppContentView: No users found")
                    isLoading = false
                    return
                }

                // ✅ Clean Architecture: Use Use Case to get groups
                let groups = try await fetchGroupsForUserUseCase.execute(userId: currentUser.id)

                await MainActor.run {
                    selectedUser = currentUser
                    selectedGroup = groups.first
                    isLoading = false
                }

                print("✅ AppContentView: Loaded user: \(currentUser.name), groups: \(groups.count)")

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
    AppContentView()
}