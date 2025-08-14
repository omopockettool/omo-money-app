import SwiftUI

/// Reusable loading view component
/// Provides consistent loading states across the app
struct LoadingView: View {
    let message: String
    let showProgress: Bool
    
    init(message: String = "Cargando...", showProgress: Bool = true) {
        self.message = message
        self.showProgress = showProgress
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if showProgress {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

/// Loading view with custom styling
struct StyledLoadingView: View {
    let message: String
    let style: LoadingStyle
    
    enum LoadingStyle {
        case `default`
        case compact
        case fullScreen
    }
    
    init(message: String = "Cargando...", style: LoadingStyle = .default) {
        self.message = message
        self.style = style
    }
    
    var body: some View {
        switch style {
        case .default:
            LoadingView(message: message)
        case .compact:
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        case .fullScreen:
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                LoadingView(message: message)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingView(message: "Cargando usuarios...")
        
        StyledLoadingView(message: "Compact loading", style: .compact)
        
        StyledLoadingView(message: "Full screen loading", style: .fullScreen)
    }
}
