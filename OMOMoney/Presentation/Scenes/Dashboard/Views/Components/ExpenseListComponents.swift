import SwiftUI

struct ExpenseListEmptyState: View {
    var body: some View {
        EmptyStateView(message: LocalizationKey.Entry.tapToAdd.localized)
    }
}

struct ExpenseListRowContainer: View {
    let itemList: SDItemList
    let formattedAmount: String
    let formattedUnpaidAmount: String?
    let rowStatus: ItemListRowStatus
    let isCompact: Bool
    let timelinePosition: TimelinePosition
    let onTap: () -> Void
    let onTogglePaid: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ExpenseRowView(
            itemList: itemList,
            formattedAmount: formattedAmount,
            formattedUnpaidAmount: formattedUnpaidAmount,
            rowStatus: rowStatus,
            onTap: onTap,
            onTogglePaid: onTogglePaid,
            isCompact: isCompact,
            timelinePosition: timelinePosition
        )
        .listRowInsets(EdgeInsets(
            top: 0,
            leading: AppConstants.UserInterface.smallPadding,
            bottom: 0,
            trailing: AppConstants.UserInterface.padding
        ))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label(LocalizationKey.General.delete.localized, systemImage: "trash")
            }
        }
    }
}

struct ExpenseListSectionHeader: View {
    let date: Date
    let isCompact: Bool
    let hideSectionHeaders: Bool
    let allowsDayCollapse: Bool
    let isCollapsed: Bool
    let total: String?
    let onToggleCollapsed: () -> Void

    var body: some View {
        if !isCompact && !hideSectionHeaders {
            HStack(spacing: 8) {
                Button(action: onToggleCollapsed) {
                    HStack(spacing: 8) {
                        if allowsDayCollapse {
                            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 12)
                        }
                        Text(DateFormatterHelper.formatSectionDate(date))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Spacer()

                        if let total {
                            Text(total)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.none)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!allowsDayCollapse)
            }
        }
    }
}
