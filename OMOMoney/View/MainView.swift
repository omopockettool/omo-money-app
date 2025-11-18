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
                // Splash screen unificado con logo OMOMoney
                SplashView()
            } else if hasUsers {
                // Main app content when users exist
                AppContentView(context: context)
            } else {
                // Empty state - show some placeholder content
                VStack {
                    Image(systemName: "plus.circle")
                        .font(.largeTitle)
                        .foregroundColor(.accentColor)
                    Text("Bienvenido a OMOMoney")
                        .font(.title)
                    Text("Crea tu primer usuario para comenzar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingCreateFirstUser) {
            CreateFirstUserView(
                isPresented: $showingCreateFirstUser,
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
        
        // Delay mínimo para mostrar el splash screen (mejor UX para branding)
        let startTime = Date()
        
        do {
            // Check if there's a current user
            let currentUser = try await userService.getCurrentUser()
            
            // Calcular tiempo transcurrido y esperar si fue muy rápido
            let elapsed = Date().timeIntervalSince(startTime)
            let minimumDisplayTime: TimeInterval = 2.0 // 2 segundos mínimo
            
            if elapsed < minimumDisplayTime {
                try? await Task.sleep(nanoseconds: UInt64((minimumDisplayTime - elapsed) * 1_000_000_000))
            }
            
            await MainActor.run {
                hasUsers = currentUser != nil
                isLoading = false
                
                // Si no hay usuarios, mostrar el sheet para crear el primero
                if !hasUsers {
                    showingCreateFirstUser = true
                }
            }
            
            print("🔍 MainView: Usuario encontrado: \(currentUser?.name ?? "ninguno"), hasUsers: \(hasUsers)")
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
