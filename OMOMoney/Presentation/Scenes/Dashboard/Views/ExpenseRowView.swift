import SwiftUI

struct ExpenseRowView: View {
    let itemList: SDItemList
    let formattedAmount: String
    let formattedUnpaidAmount: String?
    let rowStatus: ItemListRowStatus
    let onTap: () -> Void
    let onTogglePaid: () -> Void
    var isCompact: Bool = false
    var timelinePosition: TimelinePosition = .single

    private var showsZeroAmountStyle: Bool {
        abs(itemList.totalPaidAmount) < 0.000_001
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onTogglePaid) {
                TimelineRailView(
                    position: timelinePosition,
                    color: railColor,
                    isActive: railIsActive,
                    iconName: rowStatusIcon,
                    iconColor: rowStatusColor,
                    lineSegmentHeight: isCompact ? 24 : 29
                )
                .frame(width: 44)
            }
            .buttonStyle(PressHapticButtonStyle())

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(itemList.itemListDescription)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedAmount)
                        .font(.subheadline)
                        .fontWeight(showsZeroAmountStyle ? .semibold : .bold)
                        .foregroundStyle(showsZeroAmountStyle ? Color.secondary : Color.primary)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                    if let unpaid = formattedUnpaidAmount {
                        Text("\(unpaid) \(LocalizationKey.Item.unpaid.localized)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .contentTransition(.numericText())
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .layoutPriority(1)
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: formattedAmount)
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: formattedUnpaidAmount)
            }
            .frame(minHeight: isCompact ? 52 : 58, alignment: .center)
            .padding(.vertical, isCompact ? 10 : 12)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(.separator).opacity(0.15))
                    .frame(height: 2.0)
                    .frame(maxWidth: 120)
            }
        }
        .padding(.trailing, 2)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var rowStatusIcon: String? {
        switch rowStatus {
        case .neutral: return nil
        case .unpaid:  return "circle"
        case .partial: return "circle.lefthalf.filled"
        case .paid:    return "checkmark.circle.fill"
        }
    }

    private var rowStatusColor: Color {
        switch rowStatus {
        case .neutral: return Color(.systemGray3)
        case .unpaid:  return Color(.systemGray3)
        case .partial: return .orange
        case .paid:    return .green
        }
    }

    private var railColor: Color {
        rowStatus == .paid ? .green : Color(.systemGray3)
    }

    private var railIsActive: Bool {
        rowStatus != .neutral && rowStatus != .unpaid
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 10) {
        ExpenseRowView(
            itemList: SDItemList.mock(itemListDescription: "Compras del supermercado"),
            formattedAmount: "12,89 €",
            formattedUnpaidAmount: nil,
            rowStatus: .paid,
            onTap: {},
            onTogglePaid: {}
        )
        ExpenseRowView(
            itemList: SDItemList.mock(itemListDescription: "Cena en restaurante"),
            formattedAmount: "8,00 €",
            formattedUnpaidAmount: "37,60 €",
            rowStatus: .partial,
            onTap: {},
            onTogglePaid: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
