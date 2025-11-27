import SwiftUI
import CoreData

struct PaymentMethodPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var selectedPaymentMethod: PaymentMethod?
    let group: Group
    
    @StateObject private var viewModel: PaymentMethodPickerViewModel
    
    init(selectedPaymentMethod: Binding<PaymentMethod?>, group: Group, context: NSManagedObjectContext) {
        self._selectedPaymentMethod = selectedPaymentMethod
        self.group = group
        
        let paymentMethodService = PaymentMethodService(context: context)
        self._viewModel = StateObject(wrappedValue: PaymentMethodPickerViewModel(paymentMethodService: paymentMethodService))
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
            await viewModel.loadAvailablePaymentMethods(for: group)
        }
    }
    
    // MARK: - Computed Properties
    
    private var groupedPaymentMethods: [String: [PaymentMethod]] {
        Dictionary(grouping: viewModel.availablePaymentMethods) { paymentMethod in
            paymentMethod.type ?? "other"
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

struct PaymentMethodRow: View {
    let paymentMethod: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            // Payment Method Icon
            Image(systemName: paymentMethodIcon(for: paymentMethod.type ?? "other"))
                .font(.title2)
                .foregroundColor(paymentMethodColor(for: paymentMethod.type ?? "other"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(paymentMethod.name ?? "Sin nombre")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(paymentMethodTypeDisplayName(paymentMethod.type ?? "other"))
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
    let context = PersistenceController.preview.container.viewContext
    
    let group = Group(context: context)
    group.id = UUID()
    group.name = "Test Group"
    group.currency = "USD"
    
    let paymentMethod1 = PaymentMethod(context: context)
    paymentMethod1.id = UUID()
    paymentMethod1.name = "Tarjeta Visa"
    paymentMethod1.type = "card"
    paymentMethod1.isActive = true
    paymentMethod1.group = group
    
    let paymentMethod2 = PaymentMethod(context: context)
    paymentMethod2.id = UUID()
    paymentMethod2.name = "Efectivo"
    paymentMethod2.type = "cash"
    paymentMethod2.isActive = true
    paymentMethod2.group = group
    
    return PaymentMethodPickerView(
        selectedPaymentMethod: .constant(nil),
        group: group,
        context: context
    )
}