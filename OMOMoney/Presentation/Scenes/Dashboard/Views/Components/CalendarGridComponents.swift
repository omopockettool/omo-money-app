import SwiftUI

@available(iOS 26.0, *)
struct CalendarMonthHeader: View {
    let title: String
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .glassEffect(.regular.interactive(), in: .circle)
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .glassEffect(.regular.interactive(), in: .circle)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppConstants.UserInterface.smallPadding)
        .padding(.vertical, AppConstants.UserInterface.smallPadding)
    }
}

@available(iOS 26.0, *)
struct CalendarWeekdayHeaderRow: View {
    let columns: [GridItem]
    let weekdaySymbols: [String]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, AppConstants.UserInterface.smallPadding)
    }
}

@available(iOS 26.0, *)
struct CalendarDayCell: View {
    let date: Date
    let rowHeight: CGFloat
    let calendar: Calendar
    let dayTotal: Double
    let isToday: Bool
    let isSelected: Bool
    let hasItemLists: Bool
    let hasUnpaid: Bool
    let onTap: () -> Void
    let formattedAmount: (Double) -> String

    var body: some View {
        let hasSpend = hasItemLists && dayTotal > 0
        let dateColor: Color = isToday ? .accentColor : .primary
        let amountColor: Color = hasSpend ? (hasUnpaid ? .orange : .accentColor) : .secondary

        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? .accentColor : dateColor)

                if hasItemLists {
                    Text(formattedAmount(dayTotal))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(amountColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                } else {
                    Text("·")
                        .font(.system(size: 13))
                        .foregroundColor(.clear)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
