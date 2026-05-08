import Foundation

struct DateFormatterHelper {
    private static var currentLocale: Locale {
        Locale.current
    }

    static func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = currentLocale
        return formatter.string(from: date)
    }

    static func formatDateTime(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = currentLocale
        return formatter.string(from: date)
    }

    /// Returns a localized "Today", "Yesterday", "d MMM" or "d MMM yyyy" for list section headers.
    static func formatSectionDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return LocalizationKey.Dashboard.today.localized }
        if cal.isDateInYesterday(date) { return LocalizationKey.Dashboard.yesterday.localized }
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateFormat = cal.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "d MMM" : "d MMM yyyy"
        return formatter.string(from: date)
    }
}
