import Foundation
import CoreData

/// ViewModel for Entry Row functionality
/// Handles entry row display and calculations
@MainActor
class EntryRowViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var entryTotal: NSDecimalNumber = NSDecimalNumber.zero
    @Published var isCalculatingTotal = false
    
    // MARK: - Private Properties
    private let entry: Entry
    private let itemService: ItemService
    
    // MARK: - Initialization
    init(entry: Entry, context: NSManagedObjectContext) {
        self.entry = entry
        self.itemService = ItemService(context: context)
    }
    
    // MARK: - Public Methods
    
    /// Calculate total for the entry
    func calculateEntryTotal() async {
        isCalculatingTotal = true
        
        do {
            entryTotal = try await itemService.calculateTotalAmount(for: entry)
        } catch {
            entryTotal = NSDecimalNumber.zero
        }
        
        isCalculatingTotal = false
    }
    
    /// Format date for display
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Sin fecha" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "es_ES")
        
        return formatter.string(from: date)
    }
    
    /// Format currency for display
    func formatCurrency(_ amount: NSDecimalNumber, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: amount) ?? "\(amount) \(currency)"
    }
}
