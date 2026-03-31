import SwiftUI

struct ExpenseRowView: View {
    let itemList: ItemListDomain
    let formattedAmount: String
    let itemCount: Int
    let categoryName: String?
    let categoryColor: Color?
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Check circle (future: mark as paid)
            Image(systemName: "circle")
                .font(.title2)
                .foregroundStyle(Color(.systemGray3))

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

            Text(formattedAmount)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .padding(AppConstants.UserInterface.padding)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
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
            itemCount: 3,
            categoryName: "Supermercado",
            categoryColor: .green,
            onTap: {}
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
            formattedAmount: "45,60 €",
            itemCount: 1,
            categoryName: nil,
            categoryColor: nil,
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
