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
        VStack(spacing: AppConstants.UserInterface.padding) {
            HStack {
                Button(LocalizationKey.General.cancel.localized, action: onClose)
                    .buttonStyle(.plain)

                Spacer()

                Text(LocalizationKey.Dashboard.filters.localized)
                    .font(.headline)

                Spacer()

                Button(LocalizationKey.General.done.localized) {
                    onApply(selectedDate)
                }
                .buttonStyle(.plain)
                .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizationKey.Dashboard.month.localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Picker(LocalizationKey.Dashboard.month.localized, selection: $selectedMonthIndex) {
                        ForEach(Array(monthSymbols.enumerated()), id: \.offset) { index, month in
                            Text(month.capitalized(with: Locale.current)).tag(index)
                        }
                    }
                    .pickerStyle(.wheel)

                    Picker(LocalizationKey.Dashboard.year.localized, selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .frame(height: 160)
            }

            if isCustomFilterActive {
                Button(LocalizationKey.Dashboard.currentMonth.localized, action: onReset)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(AppConstants.UserInterface.padding)
        .background(Color(.systemGroupedBackground))
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
