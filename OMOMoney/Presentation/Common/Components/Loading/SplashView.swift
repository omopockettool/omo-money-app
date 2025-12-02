//
//  SplashView.swift
//  OMOMoney
//
//  Created by System on 15/11/25.
//

import SwiftUI

/// Splash screen unificado para toda la carga inicial de la app
/// Muestra el logo de OMOMoney con un mensaje de carga en español
///
/// **UX Pattern**: El splash garantiza un tiempo mínimo de visualización para:
/// 1. Permitir que el usuario reconozca el branding
/// 2. Evitar flashes rápidos que generan confusión
/// 3. Dar sensación de proceso completo y profesional
///
/// **Tiempos de delay mínimos** (configurados en cada View):
/// - DashboardView: 0.3 segundos (carga de datos) - Solo en primera carga
///
/// **Nota**: Splash solo se muestra en la primera carga.
/// Navegación posterior usa datos en cache sin mostrar splash.
struct SplashView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo OMOMoney estático (sin animación)
                VStack(spacing: 16) {
                    // Logo text
                    Text("OMO")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    +
                    Text("Money")
                        .font(.system(size: 60, weight: .light, design: .rounded))
                        .foregroundColor(.accentColor)
                    
                    // Tagline
                    Text("Tu pocket tool de finanzas.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Loading indicator - Solo el spinner gira
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.accentColor)
                    
                    Text("Cargando...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 60)
            }
            .padding()
        }
    }
}

#Preview {
    SplashView()
}
