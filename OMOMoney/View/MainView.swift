//
//  MainView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import CoreData
import SwiftUI

struct MainView: View {
    @State private var showingCreateFirstUser = false
    @State private var hasUsers = false
    @State private var isLoading = true
    
    private let context: NSManagedObjectContext
    private let userService: UserService
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.userService = UserService(context: context)
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                // Loading state
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.headline)
                        .padding(.top)
                }
            } else if hasUsers {
                // Main app content when users exist
                AppContentView(context: context)
            } else {
                // Empty state - show some placeholder content
                VStack {
                    Image(systemName: "plus.circle")
                        .font(.largeTitle)
                        .foregroundColor(.accentColor)
                    Text("Welcome to OMOMoney")
                        .font(.title)
                    Text("Create your first user to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingCreateFirstUser) {
            CreateFirstUserView(
                isPresented: $showingCreateFirstUser,
                context: context,
                onUserCreated: {
                    print("🔄 Usuario creado, recargando estado...")
                    await checkForUsers()
                    
                    // Pequeño delay para asegurar que la UI se actualice
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    
                    // Cerrar el sheet después de recargar
                    await MainActor.run {
                        showingCreateFirstUser = false
                        print("✅ Sheet cerrado, redirigiendo a AppContentView")
                    }
                }
            )
        }
        .onAppear {
            Task {
                await checkForUsers()
            }
        }
    }
}

// MARK: - Helper Functions
extension MainView {
    private func checkForUsers() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // TODO: Implement user authentication and proper user loading
            let users: [User] = [] // Placeholder until user authentication is implemented
            
            await MainActor.run {
                hasUsers = !users.isEmpty
                isLoading = false
                
                // Si no hay usuarios, mostrar el sheet para crear el primero
                if !hasUsers {
                    showingCreateFirstUser = true
                }
            }
            
            print("🔍 MainView: Usuarios encontrados: \(users.count), hasUsers: \(hasUsers)")
        } catch {
            print("❌ MainView: Error verificando usuarios: \(error)")
            await MainActor.run {
                hasUsers = false
                isLoading = false
                showingCreateFirstUser = true
            }
        }
    }
}

#Preview {
    MainView(context: PersistenceController.preview.container.viewContext)
}
