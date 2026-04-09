import SwiftUI

struct ExpenseRowView: View {
    let itemList: ItemListDomain
    let formattedAmount: String
    let formattedUnpaidAmount: String?
    let itemCount: Int
    let categoryName: String?
    let categoryColor: Color?
    let paidStatus: ItemListPaidStatus
    let onTap: () -> Void
    let onTogglePaid: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onTogglePaid) {
                Image(systemName: paidStatusIcon)
                    .font(.title2)
                    .foregroundStyle(paidStatusColor)
            }
            .buttonStyle(PressHapticButtonStyle())

            VStack(alignment: .leading, spacing: 3) {
                Text(itemList.itemListDescription)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Circle()
                        .fill(categoryColor ?? Color(.systemGray3))
                        .frame(width: 7, height: 7)
                    Text(itemCount == 1 ? "1 artículo" : "\(itemCount) artículos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let unpaid = formattedUnpaidAmount {
                    Text("\(unpaid) por pagar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .layoutPriority(1)
        }
        .padding(AppConstants.UserInterface.padding)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var paidStatusIcon: String {
        switch paidStatus {
        case .all:     return "checkmark.circle.fill"
        case .partial: return "circle.lefthalf.filled"
        case .none:    return "circle"
        }
    }

    private var paidStatusColor: Color {
        switch paidStatus {
        case .all:     return .green
        case .partial: return .orange
        case .none:    return Color(.systemGray3)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 10) {
        ExpenseRowView(
            itemList: ItemListDomain(
                id: UUID(),
                itemListDescription: "Compras del supermercado",
                date: Date(),
                categoryId: UUID(),
                paymentMethodId: UUID(),
                groupId: UUID(),
                createdAt: Date(),
                lastModifiedAt: nil
            ),
            formattedAmount: "12,89 €",
            formattedUnpaidAmount: nil,
            itemCount: 3,
            categoryName: "Supermercado",
            categoryColor: .green,
            paidStatus: .all,
            onTap: {},
            onTogglePaid: {}
        )
        ExpenseRowView(
            itemList: ItemListDomain(
                id: UUID(),
                itemListDescription: "Cena en restaurante",
                date: Date(),
                categoryId: UUID(),
                paymentMethodId: UUID(),
                groupId: UUID(),
                createdAt: Date(),
                lastModifiedAt: nil
            ),
            formattedAmount: "8,00 €",
            formattedUnpaidAmount: "37,60 €",
            itemCount: 1,
            categoryName: nil,
            categoryColor: nil,
            paidStatus: .partial,
            onTap: {},
            onTogglePaid: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
