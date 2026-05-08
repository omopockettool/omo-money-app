import SwiftUI

// MARK: - Toast Model

enum ToastType {
    case warning
    case error
    case info
}

struct ToastMessage: Equatable {
    let id: UUID
    let message: String
    let type: ToastType
    let actionTitle: String?
    let action: (() -> Void)?

    init(_ message: String, type: ToastType, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.id = UUID()
        self.message = message
        self.type = type
        self.actionTitle = actionTitle
        self.action = action
    }

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast View

struct ToastView: View {
    let toast: ToastMessage
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(toastColor)

            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            if let actionTitle = toast.actionTitle, let action = toast.action {
                Button {
                    dismissTask?.cancel()
                    onDismiss()
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.accent)
                }
                .buttonStyle(PressHapticButtonStyle())
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(PressHapticButtonStyle())
        }
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .frame(maxWidth: 400)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -40)
        .onAppear {
            Task { @MainActor in
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.prepare()
                impact.impactOccurred()
                try? await Task.sleep(for: .milliseconds(80))
                impact.impactOccurred()
                try? await Task.sleep(for: .milliseconds(80))
                impact.impactOccurred()
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isVisible = true
            }
            dismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(4.0))
                guard !Task.isCancelled else { return }
                dismiss()
            }
        }
        .onDisappear {
            dismissTask?.cancel()
        }
    }

    private var toastColor: Color {
        switch toast.type {
        case .warning: return .orange
        case .error:   return .red
        case .info:    return .accentColor
        }
    }

    private var iconName: String {
        switch toast.type {
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.octagon.fill"
        case .info:    return "info.circle.fill"
        }
    }

    private func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.25)) {
            isVisible = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.25))
            onDismiss()
        }
    }
}

// MARK: - View Modifier

extension View {
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        overlay(alignment: .top) {
            if let message = toast.wrappedValue {
                ToastView(toast: message, onDismiss: { toast.wrappedValue = nil })
                    .id(message.id)
                    .padding(.horizontal, AppConstants.UserInterface.padding)
                    .padding(.top, AppConstants.UserInterface.smallPadding)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: toast.wrappedValue)
    }
}
