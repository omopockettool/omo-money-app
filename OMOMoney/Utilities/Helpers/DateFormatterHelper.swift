import Foundation

/// Helper for date formatting operations
/// Follows MVVM architecture - no business logic, just formatting
struct DateFormatterHelper {
    
    /// Format date for display
    /// - Parameter date: Date to format
    /// - Returns: Formatted date string
    static func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "es_ES")
        
        return formatter.string(from: date)
    }
    
    /// Format date with time for display
    /// - Parameter date: Date to format
    /// - Returns: Formatted date and time string
    static func formatDateTime(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es_ES")
        
        return formatter.string(from: date)
    }
}
