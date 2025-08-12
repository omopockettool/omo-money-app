import Foundation
import CoreData
import SwiftUI

@MainActor
class EntryRowViewModel: ObservableObject {
    @Published var entryTotal: NSDecimalNumber = NSDecimalNumber.zero
    @Published var isCalculatingTotal = false
    
    private let entry: Entry
    
    init(entry: Entry) {
        self.entry = entry
    }
    
    // MARK: - Business Logic
    
    func calculateEntryTotal() {
        isCalculatingTotal = true
        
        // Since this is a simple calculation on already-loaded data,
        // we can do it directly on the main thread
        // If we need to fetch from Core Data, we would use context.perform
        let entryItems = entry.items ?? NSSet()
        let total = entryItems.reduce(NSDecimalNumber.zero) { total, item in
            guard let item = item as? Item else { return total }
            let itemAmount = item.amount ?? NSDecimalNumber.zero
            let itemQuantity = NSDecimalNumber(value: item.quantity)
            return total.safeAdd(itemAmount.multiplying(by: itemQuantity))
        }
        
        entryTotal = total
        isCalculatingTotal = false
    }
    
    // MARK: - Formatting
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func formatCurrency(_ amount: NSDecimalNumber) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // Default, should use group currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: amount) ?? "$0.00"
    }
}
