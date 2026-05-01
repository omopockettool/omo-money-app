import SwiftUI

struct ItemListDetailHeroCard: View {
    let itemList: SDItemList
    let heroIsSuccess: Bool
    let lastAddedDescription: String
    let totalAmount: String
    let heroStatus: ItemListDetailHeroStatus
    let showMetaLabels: Bool
    let onAddExpense: () -> Void

    var body: some View {
        TotalSpentCardView(
            label: heroIsSuccess ? lastAddedDescription : LocalizationKey.Item.costOf.localized(with: itemList.itemListDescription),
            totalAmount: totalAmount,
            onAddExpense: onAddExpense,
            isSuccess: heroIsSuccess
        ) {
            ItemListDetailMetaRow(
                itemList: itemList,
                heroStatus: heroStatus,
                showMetaLabels: showMetaLabels
            )
        }
    }
}

struct ItemListDetailMetaRow: View {
    let itemList: SDItemList
    let heroStatus: ItemListDetailHeroStatus
    let showMetaLabels: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let category = itemList.category {
                let color = Color(hex: category.color) ?? .accentColor
                HStack(spacing: 4) {
                    Image(systemName: category.icon)
                        .foregroundStyle(color)
                    if showMetaLabels {
                        Text(category.name)
                            .foregroundStyle(color)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .leading)))
                    }
                }
                .font(.caption)
                .fontWeight(.medium)
            }

            if let paymentMethod = itemList.paymentMethod {
                let color = paymentMethodColor(paymentMethod.type)
                HStack(spacing: 4) {
                    Image(systemName: paymentMethod.icon.isEmpty ? defaultPaymentMethodIcon(paymentMethod.type) : paymentMethod.icon)
                        .foregroundStyle(color)
                    if showMetaLabels {
                        Text(paymentMethod.name)
                            .foregroundStyle(color)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .leading)))
                    }
                }
                .font(.caption)
                .fontWeight(.medium)
            }

            Group {
                switch heroStatus {
                case .pending(let unpaidTotal):
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        if !showMetaLabels {
                            Text(unpaidTotal)
                                .fontWeight(.medium)
                                .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .leading)))
                        }
                    }
                    .foregroundStyle(.orange)
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .neutral:
                    EmptyView()
                }
            }
            .font(.caption)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: heroStatusKey)
        }
        .padding(.top, 2)
    }

    private var heroStatusKey: String {
        switch heroStatus {
        case .neutral:
            return "neutral"
        case .pending:
            return "pending"
        case .completed:
            return "completed"
        }
    }

    private func paymentMethodColor(_ type: String) -> Color {
        switch type {
        case "cash":          return .green
        case "bank_transfer": return .orange
        case "card_credit":   return .purple
        default:              return .blue
        }
    }

    private func defaultPaymentMethodIcon(_ type: String) -> String {
        switch type {
        case "cash":          return "banknote.fill"
        case "bank_transfer": return "arrow.left.arrow.right"
        default:              return "creditcard.fill"
        }
    }
}

struct ItemListItemsSection: View {
    let items: [SDItem]
    let currencyCode: String
    let formattedAmount: (SDItem) -> String
    let onItemTap: (SDItem) -> Void
    let onTogglePaid: (SDItem) -> Void
    let onDelete: (SDItem, Int) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        List {
            if items.isEmpty {
                ItemListEmptyStateRow()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ItemRowView(
                        item: item,
                        formattedAmount: formattedAmount(item),
                        currencyCode: currencyCode,
                        timelinePosition: timelinePosition(index: index, count: items.count),
                        onTap: { onItemTap(item) },
                        onTogglePaid: { onTogglePaid(item) }
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            onDelete(item, index)
                        } label: {
                            Label(LocalizationKey.General.delete.localized, systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .animation(.easeInOut(duration: 0.2), value: items.count)
        .refreshable { await onRefresh() }
    }

    private func timelinePosition(index: Int, count: Int) -> TimelinePosition {
        if count == 1 { return .single }
        if index == 0 { return .first }
        if index == count - 1 { return .last }
        return .middle
    }
}

struct ItemListEmptyStateRow: View {
    var body: some View {
        EmptyStateView(message: LocalizationKey.Item.tapToAdd.localized)
    }
}

struct ItemListErrorState: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: AppConstants.UserInterface.padding) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(LocalizationKey.General.error.localized)
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(LocalizationKey.General.retry.localized, action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding(AppConstants.UserInterface.largePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
