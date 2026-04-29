import SwiftUI

struct CreateFirstUserView: View {
    @State private var viewModel: CreateFirstUserViewModel
    @FocusState private var focusedField: Field?
    
    var onUserCreated: (() async -> Void)?
    
    enum Field: Hashable { 
        case name, email 
    }
    
    init(onUserCreated: (() async -> Void)? = nil) {
        self._viewModel = State(wrappedValue: CreateFirstUserViewModel())
        self.onUserCreated = onUserCreated
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                header
                    .padding(.top, 40)
                
                formContent
                    .padding(.horizontal, AppConstants.UserInterface.largePadding)
                
                Spacer()
            }
            .opacity(viewModel.isLoading ? 0 : 1)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Error desconocido")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 20) {
            // Icon with modern gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.2),
                                Color.accentColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.accentColor.opacity(0.2), radius: 12, y: 6)
                
                Image(systemName: "wallet.bifold.fill")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating)
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text(LocalizationKey.User.Welcome.title.localized)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(LocalizationKey.User.Welcome.subtitle.localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
    
    // MARK: - Form Content
    
    private var formContent: some View {
        VStack(spacing: 16) {
            inputField(
                icon: "person.fill",
                placeholder: LocalizationKey.User.namePlaceholder.localized,
                text: $viewModel.name,
                field: .name,
                contentType: .name,
                keyboardType: .default,
                capitalization: .words
            )

            inputField(
                icon: "envelope.fill",
                placeholder: LocalizationKey.User.emailPlaceholder.localized,
                text: $viewModel.email,
                field: .email,
                contentType: .emailAddress,
                keyboardType: .emailAddress,
                capitalization: .never
            )
            
            createButton
                .padding(.top, 8)
        }
    }
    
    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        contentType: UITextContentType,
        keyboardType: UIKeyboardType,
        capitalization: TextInputAutocapitalization
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.secondary)
                .frame(width: 24)
                .contentTransition(.symbolEffect(.replace))
            
            TextField(placeholder, text: text)
                .textContentType(contentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
                .focused($focusedField, equals: field)
                .submitLabel(field == .name ? .next : .done)
                .onSubmit {
                    if field == .name { 
                        focusedField = .email 
                    } else { 
                        focusedField = nil
                    }
                }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            focusedField == field ? Color(.systemGray3) : Color.clear,
                            lineWidth: 2
                        )
                )
        )
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Button {
            focusedField = nil
            Task {
                await viewModel.createUser()
                if viewModel.isSuccess {
                    await onUserCreated?()
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 17, weight: .semibold))
                    .symbolEffect(.bounce, value: viewModel.isFormValid)
                
                Text(LocalizationKey.User.create.localized)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if viewModel.isFormValid {
                        LinearGradient(
                            colors: [
                                Color.accentColor,
                                Color.accentColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [
                                Color(.systemFill),
                                Color(.systemFill)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: viewModel.isFormValid ? Color.accentColor.opacity(0.3) : .clear,
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(PressHapticButtonStyle())
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .animation(.smooth(duration: 0.3), value: viewModel.isFormValid)
    }
}

// MARK: - Preview

#Preview("Default") {
    CreateFirstUserView(onUserCreated: {})
}

#Preview("Dark Mode") {
    CreateFirstUserView(onUserCreated: {})
        .preferredColorScheme(.dark)
}
