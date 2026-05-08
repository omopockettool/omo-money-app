//
//  CustomAlertView.swift
//  OMOMoney
//
//  Created by System on 16/11/25.
//

import SwiftUI

/// Alert customizado reutilizable con animaciones suaves
/// Proporciona mejor control visual que el alert nativo de SwiftUI
struct CustomAlertView: View {
    let title: String
    let message: String?
    let primaryButton: AlertButton
    let secondaryButton: AlertButton?
    @Binding var isPresented: Bool
    
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Overlay semi-transparente con fade
            Color.black.opacity(showContent ? 0.4 : 0.0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAlert()
                }
            
            // Alert card
            VStack(spacing: 0) {
                // Título y mensaje
                VStack(spacing: 12) {
                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.top, 24)
                        .padding(.horizontal, 24)
                    
                    if let message = message {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                        .frame(height: 12)
                }
                
                Divider()
                
                // Botones
                HStack(spacing: 0) {
                    if let secondaryButton = secondaryButton {
                        // Botón secundario (usualmente Cancelar)
                        Button {
                            dismissAlert {
                                secondaryButton.action()
                            }
                        } label: {
                            Text(secondaryButton.title)
                                .font(.body)
                                .fontWeight(secondaryButton.style == .cancel ? .regular : .medium)
                                .foregroundColor(buttonColor(for: secondaryButton.style))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .frame(height: 44)
                    }
                    
                    // Botón primario
                    Button {
                        dismissAlert {
                            primaryButton.action()
                        }
                    } label: {
                        Text(primaryButton.title)
                            .font(.body)
                            .fontWeight(primaryButton.style == .destructive ? .semibold : .medium)
                            .foregroundColor(buttonColor(for: primaryButton.style))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .frame(width: 270)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .scaleEffect(showContent ? 1.0 : 0.9)
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                showContent = true
            }
        }
    }
    
    private func dismissAlert(completion: (() -> Void)? = nil) {
        withAnimation(.easeOut(duration: 0.25)) {
            showContent = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            isPresented = false
            completion?()
        }
    }
    
    private func buttonColor(for style: AlertButtonStyle) -> Color {
        switch style {
        case .default:
            return .accentColor
        case .cancel:
            return .primary
        case .destructive:
            return .red
        }
    }
}

// MARK: - Alert Button Model
struct AlertButton {
    let title: String
    let style: AlertButtonStyle
    let action: () -> Void
    
    init(title: String, style: AlertButtonStyle = .default, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
}

enum AlertButtonStyle {
    case `default`
    case cancel
    case destructive
}

// MARK: - View Extension for Easy Usage
extension View {
    /// Muestra un alert customizado con animaciones suaves
    /// - Parameters:
    ///   - title: Título del alert
    ///   - message: Mensaje opcional del alert
    ///   - isPresented: Binding que controla la visibilidad
    ///   - primaryButton: Botón principal (derecha)
    ///   - secondaryButton: Botón secundario opcional (izquierda)
    func customAlert(
        title: String,
        message: String? = nil,
        isPresented: Binding<Bool>,
        primaryButton: AlertButton,
        secondaryButton: AlertButton? = nil
    ) -> some View {
        ZStack {
            self
            
            if isPresented.wrappedValue {
                CustomAlertView(
                    title: title,
                    message: message,
                    primaryButton: primaryButton,
                    secondaryButton: secondaryButton,
                    isPresented: isPresented
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        CustomAlertView(
            title: "¿Desea eliminar este grupo?",
            message: "Esta acción no se puede deshacer",
            primaryButton: AlertButton(title: "Eliminar", style: .destructive) {
            },
            secondaryButton: AlertButton(title: "Cancelar", style: .cancel) {
            },
            isPresented: .constant(true)
        )
    }
}
