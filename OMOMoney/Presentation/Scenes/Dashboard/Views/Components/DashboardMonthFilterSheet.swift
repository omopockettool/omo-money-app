import SwiftUI

struct DashboardMonthFilterSheet: View {
    let selectedMonth: Date
    let availableYears: [Int]
    let isCustomFilterActive: Bool
    let onApply: (Date) -> Void
    let onReset: () -> Void
    let onClose: () -> Void

    @State private var selectedMonthIndex: Int
    @State private var selectedYear: Int

    init(
        selectedMonth: Date,
        availableYears: [Int],
        isCustomFilterActive: Bool,
        onApply: @escaping (Date) -> Void,
        onReset: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.selectedMonth = selectedMonth
        self.availableYears = availableYears
        self.isCustomFilterActive = isCustomFilterActive
        self.onApply = onApply
        self.onReset = onReset
        self.onClose = onClose

        let calendar = Calendar.current
        _selectedMonthIndex = State(initialValue: max(0, calendar.component(.month, from: selectedMonth) - 1))
        _selectedYear = State(initialValue: calendar.component(.year, from: selectedMonth))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Picker(LocalizationKey.Dashboard.month.localized, selection: $selectedMonthIndex) {
                    ForEach(Array(monthSymbols.enumerated()), id: \.offset) { index, month in
                        Text(month.capitalized(with: Locale.current)).tag(index)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                Picker(LocalizationKey.Dashboard.year.localized, selection: $selectedYear) {
                    ForEach(availableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 110)
            }
            .padding(.horizontal, 8)

            if isCustomFilterActive {
                Button(LocalizationKey.Dashboard.currentMonth.localized) {
                    onReset()
                }
                .font(.subheadline)
                .padding(.bottom, 8)
            }
        }
        .navigationTitle(LocalizationKey.Dashboard.filters.localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                PrimaryToolbarCheckButton {
                    onApply(selectedDate)
                }
            }
        }
        .presentationBackground(Color(uiColor: .systemGroupedBackground))
    }

    private var monthSymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.standaloneMonthSymbols
    }

    private var selectedDate: Date {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonthIndex + 1
        components.day = 1
        return Calendar.current.date(from: components) ?? selectedMonth
    }
}
