//
//  MainView.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI

struct MainView: View {
    @State private var hasUsers = false
    @State private var isLoading = true

    private let getCurrentUserUseCase: GetCurrentUserUseCase

    init() {
        let container = AppDIContainer.shared
        self.getCurrentUserUseCase = container.makeGetCurrentUserUseCase()
    }

    var body: some View {
        ZStack {
            if isLoading {
                SplashView()
            } else if hasUsers {
                AppContentView()
            } else {
                CreateFirstUserView(
                    onUserCreated: {
                        await checkForUsers()
                    }
                )
            }
        }
        .onAppear {
            Task { await checkForUsers() }
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
            // ✅ Clean Architecture: Use Use Case instead of Service
            let currentUser = try await getCurrentUserUseCase.execute()

            // Calcular tiempo transcurrido y esperar si fue muy rápido
            let elapsed = Date().timeIntervalSince(startTime)
            let minimumDisplayTime: TimeInterval = 1.2

            if elapsed < minimumDisplayTime {
                try? await Task.sleep(nanoseconds: UInt64((minimumDisplayTime - elapsed) * 1_000_000_000))
            }

            await MainActor.run {
                hasUsers = currentUser != nil
                isLoading = false
            }
        } catch {
            await MainActor.run {
                hasUsers = false
                isLoading = false
            }
        }
    }
}

#Preview {
    MainView()
}
