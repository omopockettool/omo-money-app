import SwiftUI

struct PaymentMethodManagementView: View {
    let group: GroupDomain

    @StateObject private var viewModel = PaymentMethodListViewModel()
    @State private var sheetMode: SheetMode?

    enum SheetMode: Identifiable {
        case add
        case edit(PaymentMethodDomain)
        var id: String {
            switch self { case .add: return "add"; case .edit(let pm): return pm.id.uuidString }
        }
    }

    var body: some View {
        List {
            ForEach(viewModel.paymentMethods) { pm in
                paymentMethodRow(pm)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !pm.isDefault {
                            Button(role: .destructive) {
                                Task { await viewModel.deletePaymentMethod(paymentMethodId: pm.id) }
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Métodos de pago")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { sheetMode = .add } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $sheetMode) { mode in
            NavigationStack {
                switch mode {
                case .add:
                    PaymentMethodFormView(group: group, methodToEdit: nil) {
                        Task { await viewModel.loadPaymentMethods(forGroupId: group.id) }
                    }
                case .edit(let pm):
                    PaymentMethodFormView(group: group, methodToEdit: pm) {
                        Task { await viewModel.loadPaymentMethods(forGroupId: group.id) }
                    }
                }
            }
        }
        .task { await viewModel.loadPaymentMethods(forGroupId: group.id) }
    }

    private func paymentMethodRow(_ pm: PaymentMethodDomain) -> some View {
        Button { if !pm.isDefault { sheetMode = .edit(pm) } } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(typeColor(pm.type).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: pm.icon.isEmpty ? typeIcon(pm.type) : pm.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(typeColor(pm.type))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(pm.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(typeName(pm.type))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if pm.isDefault {
                    Text("Predeterminado")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private func typeIcon(_ type: String) -> String {
        switch type {
        case "cash":         return "banknote.fill"
        case "bank_transfer": return "arrow.left.arrow.right"
        case "card_credit":  return "creditcard.fill"
        default:             return "creditcard.fill"  // card_debit
        }
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "cash":         return .green
        case "bank_transfer": return .orange
        case "card_credit":  return .purple
        default:             return .blue  // card_debit
        }
    }

    private func typeName(_ type: String) -> String {
        switch type {
        case "cash":         return "Efectivo"
        case "card_debit":   return "T. Débito"
        case "card_credit":  return "T. Crédito"
        case "bank_transfer": return "Transferencia"
        default:             return type
        }
    }
}
