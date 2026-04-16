import SwiftUI
import SwiftData

struct PaymentMethodPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedPaymentMethod: SDPaymentMethod?
    let groupId: UUID

    @Query(sort: \SDPaymentMethod.name) private var allPaymentMethods: [SDPaymentMethod]

    private var availablePaymentMethods: [SDPaymentMethod] {
        allPaymentMethods.filter { $0.group?.id == groupId && $0.isActive }
    }

    private var groupedPaymentMethods: [String: [SDPaymentMethod]] {
        Dictionary(grouping: availablePaymentMethods) { $0.type }
    }

    init(selectedPaymentMethod: Binding<SDPaymentMethod?>, groupId: UUID) {
        self._selectedPaymentMethod = selectedPaymentMethod
        self.groupId = groupId
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if availablePaymentMethods.isEmpty {
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
    }

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
    let paymentMethod: SDPaymentMethod
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
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
