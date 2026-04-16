import SwiftUI
import SwiftData

struct PaymentMethodPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedPaymentMethod: SDPaymentMethod?
    let groupId: UUID

    @State private var viewModel: PaymentMethodPickerViewModel

    init(selectedPaymentMethod: Binding<SDPaymentMethod?>, groupId: UUID) {
        self._selectedPaymentMethod = selectedPaymentMethod
        self.groupId = groupId
        self._viewModel = State(wrappedValue: PaymentMethodPickerViewModel())
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                        Text("Cargando métodos de pago...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.availablePaymentMethods.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No hay métodos de pago")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Crea un método de pago en la configuración del grupo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Payment Methods List
                    List {
                        ForEach(groupedPaymentMethods.keys.sorted(), id: \.self) { type in
                            Section(header: Text(paymentMethodTypeDisplayName(type))) {
                                ForEach(groupedPaymentMethods[type] ?? [], id: \.id) { paymentMethod in
                                    PaymentMethodRow(
                                        paymentMethod: paymentMethod,
                                        isSelected: selectedPaymentMethod?.id == paymentMethod.id
                                    ) {
                                        selectedPaymentMethod = paymentMethod
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Seleccionar Método de Pago")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ninguno") {
                        selectedPaymentMethod = nil
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            await viewModel.loadAvailablePaymentMethods(forGroupId: groupId)
        }
    }

    // MARK: - Computed Properties

    private var groupedPaymentMethods: [String: [SDPaymentMethod]] {
        Dictionary(grouping: viewModel.availablePaymentMethods) { paymentMethod in
            paymentMethod.type
        }
    }
    
    // MARK: - Helper Methods
    
    private func paymentMethodTypeDisplayName(_ type: String) -> String {
        switch type.lowercased() {
        case "card":
            return "Tarjetas"
        case "cash":
            return "Efectivo"
        case "transfer":
            return "Transferencias"
        case "digital":
            return "Billeteras Digitales"
        default:
            return "Otros"
        }
    }
}

// MARK: - PaymentMethodRow

/// ✅ REFACTORED: Uses SDPaymentMethod
struct PaymentMethodRow: View {
    let paymentMethod: SDPaymentMethod
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            // Payment Method Icon
            Image(systemName: paymentMethodIcon(for: paymentMethod.type))
                .font(.title2)
                .foregroundColor(paymentMethodColor(for: paymentMethod.type))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(paymentMethod.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(paymentMethodTypeDisplayName(paymentMethod.type))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func paymentMethodIcon(for type: String) -> String {
        switch type.lowercased() {
        case "card":
            return "creditcard.fill"
        case "cash":
            return "banknote.fill"
        case "transfer":
            return "arrow.left.arrow.right"
        case "digital":
            return "iphone"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func paymentMethodColor(for type: String) -> Color {
        switch type.lowercased() {
        case "card":
            return .blue
        case "cash":
            return .green
        case "transfer":
            return .orange
        case "digital":
            return .purple
        default:
            return .gray
        }
    }
    
    private func paymentMethodTypeDisplayName(_ type: String) -> String {
        switch type.lowercased() {
        case "card":
            return "Tarjeta"
        case "cash":
            return "Efectivo"
        case "transfer":
            return "Transferencia"
        case "digital":
            return "Digital"
        default:
            return "Otro"
        }
    }
}

// MARK: - Preview

#Preview {
    PaymentMethodPickerView(
        selectedPaymentMethod: .constant(nil),
        groupId: UUID()
    )
    .modelContainer(ModelContainer.preview)
}