import Foundation

/// Application constants and configuration
struct AppConstants {
    
    // MARK: - Available Currencies
    static let availableCurrencies = [
        "USD", "EUR", "GBP", "JPY", "CAD", "AUD", 
        "CHF", "CNY", "MXN", "BRL", "INR", "KRW"
    ]
    
    // MARK: - Default Values
    static let defaultCurrency = "USD"
    static let defaultCategoryColor = "#007AFF"
    
    // MARK: - Validation Rules
    struct Validation {
        static let minNameLength = 2
        static let maxNameLength = 50
        static let minEmailLength = 5
        static let maxEmailLength = 100
    }
    
    // MARK: - UI Constants
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
    }
    
    // MARK: - Date Formatting
    struct DateFormat {
        static let displayFormat = "dd MMM yyyy"
        static let shortFormat = "dd/MM/yy"
        static let timeFormat = "HH:mm"
    }
}
