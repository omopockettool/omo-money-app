//
//  CalendarGridView.swift
//  OMOMoney
//

import SwiftUI

struct CalendarGridView: View {
    let currentMonthItemLists: [ItemListDomain]
    let itemListTotals: [UUID: Double]
    let currencyCode: String
    let selectedDay: Date?
    let onDayTap: (Date) -> Void

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    // MARK: - Computed

    private var dailyTotals: [Date: Double] {
        var result: [Date: Double] = [:]
        for itemList in currentMonthItemLists {
            guard calendar.isDate(itemList.date, equalTo: displayedMonth, toGranularity: .month) else { continue }
            let day = calendar.startOfDay(for: itemList.date)
            result[day, default: 0] += itemListTotals[itemList.id] ?? 0
        }
        return result
    }

    private var maxDailyTotal: Double {
        dailyTotals.values.max() ?? 1
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
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(weekRow.indices, id: \.self) { i in
                        if let date = weekRow[i] {
                            dayCell(for: date)
                        } else {
                            Color.clear.frame(height: 56)
                        }
                    }
                }
                .padding(.horizontal, AppConstants.UserInterface.smallPadding)
                .padding(.vertical, 4)
                .transition(.opacity)
            } else {
                // Full month grid
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(daysInGrid.indices, id: \.self) { i in
                        if let date = daysInGrid[i] {
                            dayCell(for: date)
                        } else {
                            Color.clear.frame(height: 56)
                        }
                    }
                }
                .padding(.horizontal, AppConstants.UserInterface.smallPadding)
                .padding(.vertical, 4)
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Text(monthTitle)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, AppConstants.UserInterface.smallPadding)
        .padding(.vertical, AppConstants.UserInterface.smallPadding)
    }

    private var weekdayHeaders: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, AppConstants.UserInterface.smallPadding)
    }

    private func dayCell(for date: Date) -> some View {
        let dayTotal = dailyTotals[calendar.startOfDay(for: date)] ?? 0
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let hasSpend = dayTotal > 0
        let pillOpacity = hasSpend ? max(0.35, dayTotal / maxDailyTotal) : 0

        return Button {
            onDayTap(date)
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 30, height: 30)
                    } else if isToday {
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 1.5)
                            .frame(width: 30, height: 30)
                    }
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 14, weight: isToday || isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? .white : (isToday ? .accentColor : .primary))
                }
                .frame(width: 32, height: 32)

                if hasSpend {
                    Text(formattedAmount(dayTotal))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.accentColor)
                        .opacity(pillOpacity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Color.clear.frame(height: 12)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // In week-strip mode all visible days are tappable; in full mode only days with spend
        .disabled(selectedDay == nil && !hasSpend)
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

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
