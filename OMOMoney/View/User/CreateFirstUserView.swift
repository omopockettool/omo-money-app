import SwiftUI

struct CreateFirstUserView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = CreateFirstUserViewModel()
    var onUserCreated: (() -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("¡Bienvenido a OMOMoney!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Crea tu primer usuario para empezar a gestionar tus gastos")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nombre")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Tu nombre", text: $viewModel.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("tu@email.com", text: $viewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Create Button
                Button(action: {
                    Task {
                        await viewModel.createUser()
                        if viewModel.isSuccess {
                            onUserCreated?()
                            isPresented = false
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "person.badge.plus")
                        }
                        
                        Text(viewModel.isLoading ? "Creando..." : "Crear Usuario")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationTitle("Primer Usuario")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "Error desconocido")
            }
        }
    }
}

#Preview {
    CreateFirstUserView(isPresented: .constant(true), onUserCreated: nil)
}
