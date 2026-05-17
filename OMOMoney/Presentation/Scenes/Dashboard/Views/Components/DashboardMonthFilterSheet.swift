import SwiftUI

struct DashboardMonthFilterSheet: View {
    let selectedMonth: Date
    let availableYears: [Int]
    let isCustomFilterActive: Bool
    let isPendingFilterActive: Bool
    let onApply: (Date, DashboardPendingFilter) -> Void
    let onReset: () -> Void
    let onClose: () -> Void

    @State private var selectedMonthIndex: Int
    @State private var selectedYear: Int
    @State private var pendingFilter: DashboardPendingFilter

    init(
        selectedMonth: Date,
        availableYears: [Int],
        isCustomFilterActive: Bool,
        isPendingFilterActive: Bool,
        selectedPendingFilter: DashboardPendingFilter,
        onApply: @escaping (Date, DashboardPendingFilter) -> Void,
        onReset: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.selectedMonth = selectedMonth
        self.availableYears = availableYears
        self.isCustomFilterActive = isCustomFilterActive
        self.isPendingFilterActive = isPendingFilterActive
        self.onApply = onApply
        self.onReset = onReset
        self.onClose = onClose

        let calendar = Calendar.current
        _selectedMonthIndex = State(initialValue: max(0, calendar.component(.month, from: selectedMonth) - 1))
        _selectedYear = State(initialValue: calendar.component(.year, from: selectedMonth))
        _pendingFilter = State(initialValue: selectedPendingFilter)
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
            .padding(.top, 8)

            HStack(spacing: 12) {
                Text(LocalizationKey.Dashboard.itemStatus.localized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                Picker(LocalizationKey.Dashboard.itemStatus.localized, selection: $pendingFilter) {
                    ForEach(DashboardPendingFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.menu)
                .tint(.accentColor)
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
            .padding(.horizontal, AppConstants.UserInterface.padding)
            .padding(.top, 16)
            .padding(.bottom, 20)

            if isCustomFilterActive || isPendingFilterActive {
                Button {
                    pendingFilter = .all
                    onReset()
                } label: {
                    Text(LocalizationKey.Dashboard.clearFilters.localized)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppConstants.UserInterface.padding)
                .padding(.bottom, 20)
            } else {
                Color.clear
                    .frame(height: 20)
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
                    onApply(selectedDate, pendingFilter)
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
