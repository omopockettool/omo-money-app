//
//  CalendarGridView.swift
//  OMOMoney
//

import SwiftUI

struct CalendarGridView: View {
    let itemLists: [ItemListDomain]
    let itemListTotals: [UUID: Double]
    let currencyCode: String
    let selectedDay: Date?
    let onDayTap: (Date) -> Void
    let onMonthChange: (Date) -> Void

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    // MARK: - Computed

    private var dailyTotals: [Date: Double] {
        var result: [Date: Double] = [:]
        for itemList in itemLists {
            guard calendar.isDate(itemList.date, equalTo: displayedMonth, toGranularity: .month) else { continue }
            let day = calendar.startOfDay(for: itemList.date)
            result[day, default: 0] += itemListTotals[itemList.id] ?? 0
        }
        return result
    }

    private var daysInGrid: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        let firstWeekday = weekdayIndex(for: monthStart)
        var slots: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                slots.append(date)
            }
        }
        return slots
    }

    // Week rows (used for week-strip mode)
    private var weeks: [[Date?]] {
        stride(from: 0, to: daysInGrid.count, by: 7).map { start in
            Array(daysInGrid[start..<min(start + 7, daysInGrid.count)])
        }
    }

    private var selectedWeekRow: [Date?]? {
        guard let day = selectedDay else { return nil }
        return weeks.first { row in
            row.contains { slot in
                guard let slot else { return false }
                return calendar.isDate(slot, inSameDayAs: day)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
            weekdayHeaders

            if let weekRow = selectedWeekRow {
                // Collapsed: only the week containing the selected day
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(weekRow.indices, id: \.self) { i in
                        if let date = weekRow[i] {
                            dayCell(for: date, rowHeight: 64)
                        } else {
                            Color.clear.frame(height: 64)
                        }
                    }
                }
                .padding(.horizontal, AppConstants.UserInterface.smallPadding)
                .padding(.vertical, 4)
                .transition(.opacity)
            } else {
                // Full month grid — GeometryReader fills available height, capped at 72pt per row
                GeometryReader { geo in
                    let rowCount = CGFloat(max(weeks.count, 1))
                    let totalSpacing = 4 * (rowCount - 1)
                    let rowHeight = min((geo.size.height - totalSpacing) / rowCount, 72)
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(daysInGrid.indices, id: \.self) { i in
                            if let date = daysInGrid[i] {
                                dayCell(for: date, rowHeight: rowHeight)
                            } else {
                                Color.clear.frame(height: rowHeight)
                            }
                        }
                    }
                    .padding(.horizontal, AppConstants.UserInterface.smallPadding)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, AppConstants.UserInterface.smallPadding)
        .padding(.bottom, AppConstants.UserInterface.smallPadding)
    }

    // MARK: - Subviews

    private var monthHeader: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text(monthTitle)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, AppConstants.UserInterface.smallPadding)
        .padding(.vertical, AppConstants.UserInterface.smallPadding)
    }

    private var weekdayHeaders: some View {
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

    private func dayCell(for date: Date, rowHeight: CGFloat) -> some View {
        let dayKey     = calendar.startOfDay(for: date)
        let dayTotal   = dailyTotals[dayKey] ?? 0
        let isToday    = calendar.isDateInToday(date)
        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let hasSpend   = dailyTotals[dayKey] != nil && dayTotal > 0

        let dateColor: Color = isToday ? .accentColor : .primary
        let amountColor: Color = .accentColor

        return Button { onDayTap(date) } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? .accentColor : dateColor)

                if hasSpend {
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

    // MARK: - Helpers

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "MMMM yyyy"
        let title = formatter.string(from: displayedMonth)
        return title.prefix(1).uppercased() + title.dropFirst()
    }

    private var weekdaySymbols: [String] {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "es_ES")
        let symbols = cal.veryShortWeekdaySymbols
        // Reorder to Monday-first: L, M, X, J, V, S, D
        return Array(symbols[1...]) + [symbols[0]]
    }

    private func weekdayIndex(for date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "es_ES")
        let weekday = cal.component(.weekday, from: date)
        return (weekday + 5) % 7
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = calendar.startOfMonth(for: newMonth)
        onMonthChange(displayedMonth)
    }

    private func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "es_ES")
        let sym = NumberFormatter()
        sym.numberStyle = .currency
        sym.currencyCode = currencyCode
        sym.locale = Locale(identifier: "en_US")
        formatter.currencySymbol = sym.currencySymbol
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
