import CoreData
import Foundation

/// ViewModel for ItemList Row functionality
/// Handles itemList row display and calculations
@MainActor
class ItemListRowViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var itemListTotal = NSDecimalNumber.zero
    @Published var isCalculatingTotal = false
    
    // MARK: - Private Properties
    private let itemList: ItemList
    private let itemService: any ItemServiceProtocol
    
    // MARK: - Initialization
    init(itemList: ItemList, itemService: any ItemServiceProtocol) {
        self.itemList = itemList
        self.itemService = itemService
    }
    
    // MARK: - Public Methods
    
    /// Calculate total for the itemList
    func calculateItemListTotal() async {
        isCalculatingTotal = true
        
        do {
            itemListTotal = try await itemService.calculateTotalAmount(for: itemList)
        } catch {
            itemListTotal = NSDecimalNumber.zero
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
