import Foundation
import SwiftData

@Model
final class SDItem {
    @Attribute(.unique) var id: UUID
    var itemDescription: String
    var amount: Double
    var quantity: Int
    var isPaid: Bool
    var createdAt: Date
    var lastModifiedAt: Date?
    
    var itemList: SDItemList?
    
    init(
        id: UUID = UUID(),
        itemDescription: String = "",
        amount: Double = 0.0,
        quantity: Int = 1,
        isPaid: Bool = false,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) {
        self.id = id
        self.itemDescription = itemDescription
        self.amount = amount
        self.quantity = quantity
        self.isPaid = isPaid
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }
}

extension SDItem: Identifiable {}

extension SDItem {
    var isValid: Bool {
        !itemDescription.isEmpty && amount > 0 && quantity > 0
    }
    
    func validate() throws {
        guard !itemDescription.isEmpty else {
            throw ValidationError.emptyItemDescription
        }
        
        guard amount > 0 else {
            throw ValidationError.invalidAmount
        }
        
        guard quantity > 0 else {
            throw ValidationError.invalidQuantity
        }
    }
}

extension SDItem {
    var totalAmount: Double {
        guard amount.isFinite && !amount.isNaN else { return 0.0 }
        return amount * Double(quantity)
    }
    
    var amountDecimal: Decimal {
        Decimal(amount)
    }
    
    var totalAmountDecimal: Decimal {
        amountDecimal * Decimal(quantity)
    }
    
    func formattedAmount(currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    func formattedTotalAmount(currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "$0.00"
    }
}

extension SDItem {
    func togglePaid() {
        isPaid.toggle()
        lastModifiedAt = Date()
    }
    
    func markAsPaid() {
        isPaid = true
        lastModifiedAt = Date()
    }
    
    func markAsUnpaid() {
        isPaid = false
        lastModifiedAt = Date()
    }
    
    func updateQuantity(to newQuantity: Int) throws {
        guard newQuantity > 0 else {
            throw ValidationError.invalidQuantity
        }
        quantity = newQuantity
        lastModifiedAt = Date()
    }
    
    func updateAmount(to newAmount: Double) throws {
        guard newAmount > 0 else {
            throw ValidationError.invalidAmount
        }
        amount = newAmount
        lastModifiedAt = Date()
    }
}

#if DEBUG
extension SDItem {
    static func mock(
        id: UUID = UUID(),
        itemDescription: String = "Test Item",
        amount: Double = 10.0,
        quantity: Int = 1,
        isPaid: Bool = false,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil,
        itemList: SDItemList? = nil
    ) -> SDItem {
        let item = SDItem(
            id: id,
            itemDescription: itemDescription,
            amount: amount,
            quantity: quantity,
            isPaid: isPaid,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
        item.itemList = itemList
        return item
    }
}
#endif
