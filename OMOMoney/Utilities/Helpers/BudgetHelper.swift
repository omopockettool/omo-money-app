import Foundation

/// Helper class for budget calculations and limit validations
/// Provides utilities for category spending analysis and budget alerts
class BudgetHelper {
    
    // MARK: - Budget Alert Thresholds
    
    enum AlertThreshold {
        case warning // 75% of limit
        case danger  // 90% of limit
        case exceeded // over 100% of limit
    }
    
    // MARK: - Frequency Types
    
    enum LimitFrequency: String, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
        
        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
    }
    
    // MARK: - Budget Status Methods
    
    /// Determine alert threshold based on spending percentage
    static func getAlertThreshold(for percentage: Double) -> AlertThreshold? {
        switch percentage {
        case 1.0...:
            return .exceeded
        case 0.9..<1.0:
            return .danger
        case 0.75..<0.9:
            return .warning
        default:
            return nil
        }
    }
    
    /// Generate user-friendly budget status message
    static func getBudgetStatusMessage(
        categoryName: String,
        spending: Decimal,
        limit: Decimal,
        frequency: String,
        currency: String = "USD"
    ) -> String {
        let percentage = Double(truncating: spending as NSNumber) / Double(truncating: limit as NSNumber)
        let remainingAmount = max(0, limit - spending)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        
        let spendingString = formatter.string(from: spending as NSNumber) ?? "\(spending)"
        let limitString = formatter.string(from: limit as NSNumber) ?? "\(limit)"
        let remainingString = formatter.string(from: remainingAmount as NSNumber) ?? "\(remainingAmount)"
        
        let frequencyText = frequency.lowercased()
        
        switch getAlertThreshold(for: percentage) {
        case .exceeded:
            let overAmount = spending - limit
            let overString = formatter.string(from: overAmount as NSNumber) ?? "\(overAmount)"
            return "⚠️ \(categoryName): Over budget by \(overString) this \(frequencyText)"
            
        case .danger:
            return "🔶 \(categoryName): \(spendingString)/\(limitString) spent this \(frequencyText). \(remainingString) remaining"
            
        case .warning:
            return "🟡 \(categoryName): \(spendingString)/\(limitString) spent this \(frequencyText). \(remainingString) remaining"
            
        case .none:
            return "✅ \(categoryName): \(spendingString)/\(limitString) spent this \(frequencyText). \(remainingString) remaining"
        }
    }
    
    /// Check if budget period has changed (useful for notifications)
    static func hasBudgetPeriodChanged(
        frequency: String,
        lastCheckDate: Date,
        currentDate: Date = Date()
    ) -> Bool {
        let calendar = Calendar.current
        
        switch frequency.lowercased() {
        case "daily":
            return !calendar.isDate(lastCheckDate, inSameDayAs: currentDate)
        case "weekly":
            return !calendar.isDate(lastCheckDate, equalTo: currentDate, toGranularity: .weekOfYear)
        case "yearly":
            return !calendar.isDate(lastCheckDate, equalTo: currentDate, toGranularity: .year)
        default: // "monthly"
            return !calendar.isDate(lastCheckDate, equalTo: currentDate, toGranularity: .month)
        }
    }
    
    /// Get progress percentage for UI display
    static func getProgressPercentage(spending: Decimal, limit: Decimal) -> Double {
        guard limit > 0 else { return 0.0 }
        let percentage = Double(truncating: spending as NSNumber) / Double(truncating: limit as NSNumber)
        return min(1.0, max(0.0, percentage))
    }
    
    /// Get days remaining in current budget period
    static func getDaysRemainingInPeriod(frequency: String, currentDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        
        switch frequency.lowercased() {
        case "daily":
            return 0 // Same day
            
        case "weekly":
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else { return 0 }
            return calendar.dateComponents([.day], from: currentDate, to: weekInterval.end).day ?? 0
            
        case "yearly":
            guard let yearInterval = calendar.dateInterval(of: .year, for: currentDate) else { return 0 }
            return calendar.dateComponents([.day], from: currentDate, to: yearInterval.end).day ?? 0
            
        default: // "monthly"
            guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else { return 0 }
            return calendar.dateComponents([.day], from: currentDate, to: monthInterval.end).day ?? 0
        }
    }
    
    /// Calculate average daily spending rate for projections
    static func getAverageDailySpending(
        spending: Decimal,
        frequency: String,
        currentDate: Date = Date()
    ) -> Decimal {
        let calendar = Calendar.current
        let daysPassed: Int
        
        switch frequency.lowercased() {
        case "daily":
            daysPassed = 1
            
        case "weekly":
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else { return 0 }
            daysPassed = max(1, calendar.dateComponents([.day], from: weekInterval.start, to: currentDate).day ?? 1)
            
        case "yearly":
            guard let yearInterval = calendar.dateInterval(of: .year, for: currentDate) else { return 0 }
            daysPassed = max(1, calendar.dateComponents([.day], from: yearInterval.start, to: currentDate).day ?? 1)
            
        default: // "monthly"
            guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else { return 0 }
            daysPassed = max(1, calendar.dateComponents([.day], from: monthInterval.start, to: currentDate).day ?? 1)
        }
        
        return spending / Decimal(daysPassed)
    }
    
    /// Project end-of-period spending based on current rate
    static func getProjectedSpending(
        currentSpending: Decimal,
        frequency: String,
        currentDate: Date = Date()
    ) -> Decimal {
        let dailyAverage = getAverageDailySpending(spending: currentSpending, frequency: frequency, currentDate: currentDate)
        let daysRemaining = getDaysRemainingInPeriod(frequency: frequency, currentDate: currentDate)
        
        return currentSpending + (dailyAverage * Decimal(daysRemaining))
    }
}