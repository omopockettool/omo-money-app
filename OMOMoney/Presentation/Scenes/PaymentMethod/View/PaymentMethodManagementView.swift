import SwiftUI

struct PaymentMethodManagementView: View {
    let group: SDGroup

    @State private var viewModel = PaymentMethodListViewModel()
    @State private var sheetMode: SheetMode?

    enum SheetMode: Identifiable {
        case add
        case edit(SDPaymentMethod)
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
                        Button(role: .destructive) {
                            Task { await viewModel.deletePaymentMethod(paymentMethodId: pm.id) }
                        } label: {
                            Label(LocalizationKey.General.delete.localized, systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(LocalizationKey.Payment.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert(LocalizationKey.General.error.localized, isPresented: $viewModel.showError) {
            Button(LocalizationKey.General.ok.localized, role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PrimaryToolbarAddButton {
                    sheetMode = .add
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

    private func paymentMethodRow(_ pm: SDPaymentMethod) -> some View {
        Button { sheetMode = .edit(pm) } label: {
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
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private func typeIcon(_ type: String) -> String {
        switch type {
        case "cash":          return "banknote.fill"
        case "bank_transfer": return "arrow.left.arrow.right"
        case "card_credit":   return "creditcard.fill"
        default:              return "creditcard.fill"
        }
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "cash":          return .green
        case "bank_transfer": return .orange
        case "card_credit":   return .purple
        default:              return .blue
        }
    }

    private func typeName(_ type: String) -> String {
        switch type {
        case "cash":          return LocalizationKey.Payment.cash.localized
        case "card_debit":    return LocalizationKey.Payment.debit.localized
        case "card_credit":   return LocalizationKey.Payment.credit.localized
        case "bank_transfer": return LocalizationKey.Payment.transfer.localized
        default:              return type
        }
    }
}
