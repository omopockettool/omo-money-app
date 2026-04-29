import SwiftUI

struct ExpenseRowView: View {
    let itemList: SDItemList
    let formattedAmount: String
    let formattedUnpaidAmount: String?
    let itemCount: Int
    let categoryName: String?
    let categoryColor: Color?
    let categoryIcon: String?
    let paidStatus: ItemListPaidStatus
    let onTap: () -> Void
    let onTogglePaid: () -> Void
    var isCompact: Bool = false
    var timelinePosition: TimelinePosition = .single

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onTogglePaid) {
                TimelineRailView(
                    position: timelinePosition,
                    color: paidStatus == .all ? .green : Color(.systemGray3),
                    isActive: paidStatus != .none,
                    iconName: paidStatusIcon,
                    iconColor: paidStatusColor
                )
                .frame(width: 44)
            }
            .buttonStyle(PressHapticButtonStyle())

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(itemList.itemListDescription)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Image(systemName: categoryIcon ?? "tag.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(categoryColor ?? Color(.systemGray3))
                        Text(itemCount == 1 ? "1 artículo" : "\(itemCount) artículos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedAmount)
                        .font(.subheadline)
                        .fontWeight(.bold)
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
            .padding(.vertical, isCompact ? 12 : 14)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(.separator).opacity(0.18))
                    .frame(height: 0.5)
                    .padding(.leading, 2)
            }
        }
        .padding(.trailing, 2)
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
            itemList: SDItemList.mock(itemListDescription: "Compras del supermercado"),
            formattedAmount: "12,89 €",
            formattedUnpaidAmount: nil,
            itemCount: 3,
            categoryName: "Supermercado",
            categoryColor: .green,
            categoryIcon: "cart.fill",
            paidStatus: .all,
            onTap: {},
            onTogglePaid: {}
        )
        ExpenseRowView(
            itemList: SDItemList.mock(itemListDescription: "Cena en restaurante"),
            formattedAmount: "8,00 €",
            formattedUnpaidAmount: "37,60 €",
            itemCount: 1,
            categoryName: nil,
            categoryColor: nil,
            categoryIcon: nil,
            paidStatus: .partial,
            onTap: {},
            onTogglePaid: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
