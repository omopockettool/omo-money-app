import Foundation
import SwiftData

@Model
final class SDItemList {
    @Attribute(.unique) var id: UUID
    var itemListDescription: String
    var date: Date
    var createdAt: Date
    var lastModifiedAt: Date?
    
    var group: SDGroup?
    var category: SDCategory?
    var paymentMethod: SDPaymentMethod?
    
    @Relationship(deleteRule: .cascade, inverse: \SDItem.itemList)
    var items: [SDItem] = []
    
    init(
        id: UUID = UUID(),
        itemListDescription: String = "",
        date: Date = Date(),
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) {
        self.id = id
        self.itemListDescription = itemListDescription
        self.date = date
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }
}

extension SDItemList: Identifiable {}

extension SDItemList {
    var isValid: Bool {
        true
    }
}

extension SDItemList {
    var totalAmount: Double {
        items.reduce(0.0) { total, item in
            total + item.totalAmount
        }
    }
    
    var totalPaidAmount: Double {
        items.filter { $0.isPaid }.reduce(0.0) { total, item in
            total + item.totalAmount
        }
    }
    
    var totalUnpaidAmount: Double {
        items.filter { !$0.isPaid }.reduce(0.0) { total, item in
            total + item.totalAmount
        }
    }
    
    var itemCount: Int {
        items.count
    }
    
    var paidItemCount: Int {
        items.filter { $0.isPaid }.count
    }
    
    var unpaidItemCount: Int {
        items.filter { !$0.isPaid }.count
    }
    
    var isFullyPaid: Bool {
        !items.isEmpty && items.allSatisfy { $0.isPaid }
    }
    
    var isPartiallyPaid: Bool {
        let paidCount = paidItemCount
        return paidCount > 0 && paidCount < itemCount
    }
    
    var isUnpaid: Bool {
        paidItemCount == 0
    }
    
    var paymentStatus: PaymentStatus {
        if items.isEmpty || isUnpaid {
            return .unpaid
        } else if isFullyPaid {
            return .paid
        } else {
            return .partial
        }
    }
    
    enum PaymentStatus {
        case unpaid
        case partial
        case paid
        
        var displayText: String {
            switch self {
            case .unpaid: return "Unpaid"
            case .partial: return "Partially Paid"
            case .paid: return "Paid"
            }
        }
        
        var iconName: String {
            switch self {
            case .unpaid: return "circle"
            case .partial: return "circle.lefthalf.filled"
            case .paid: return "checkmark.circle.fill"
            }
        }
    }
}

extension SDItemList {
    func toggleAllItemsPaid(to isPaid: Bool) {
        items.forEach { $0.isPaid = isPaid }
        lastModifiedAt = Date()
    }
    
    func addItem(_ item: SDItem) {
        items.append(item)
        item.itemList = self
        lastModifiedAt = Date()
    }
    
    func removeItem(_ item: SDItem) {
        items.removeAll { $0.id == item.id }
        lastModifiedAt = Date()
    }
}

#if DEBUG
extension SDItemList {
    static func mock(
        id: UUID = UUID(),
        itemListDescription: String = "Shopping",
        date: Date = Date(),
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil,
        category: SDCategory? = nil,
        paymentMethod: SDPaymentMethod? = nil,
        group: SDGroup? = nil
    ) -> SDItemList {
        let itemList = SDItemList(
            id: id,
            itemListDescription: itemListDescription,
            date: date,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
        itemList.category = category
        itemList.paymentMethod = paymentMethod
        itemList.group = group
        return itemList
    }
}
#endif
