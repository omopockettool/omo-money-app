import Foundation
import SwiftData

@Model
final class SDPaymentMethod {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: String
    var icon: String
    var color: String
    var isActive: Bool
    var createdAt: Date
    var lastModifiedAt: Date?
    
    var group: SDGroup?
    
    @Relationship(deleteRule: .nullify, inverse: \SDItemList.paymentMethod)
    var itemLists: [SDItemList] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        type: String = "card",
        icon: String = "creditcard.fill",
        color: String = "#8E8E93",
        isActive: Bool = true,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.icon = icon
        self.color = color
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }
}

extension SDPaymentMethod: Identifiable {}

extension SDPaymentMethod {
    var isValid: Bool {
        !name.isEmpty
    }
    
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyPaymentMethodName
        }
    }
}

extension SDPaymentMethod {
    func totalSpent(in timeframe: Timeframe = .thisMonth) -> Double {
        let calendar = Calendar.current
        let now = Date()
        
        let filteredLists = itemLists.filter { itemList in
            switch timeframe {
            case .thisMonth:
                return calendar.isDate(itemList.date, equalTo: now, toGranularity: .month)
            case .thisWeek:
                return calendar.isDate(itemList.date, equalTo: now, toGranularity: .weekOfYear)
            case .thisYear:
                return calendar.isDate(itemList.date, equalTo: now, toGranularity: .year)
            case .allTime:
                return true
            }
        }
        
        return filteredLists.reduce(0.0) { total, itemList in
            total + itemList.totalAmount
        }
    }
    
    enum Timeframe {
        case thisWeek
        case thisMonth
        case thisYear
        case allTime
    }
    
    enum PaymentType: String, CaseIterable {
        case card = "card"
        case cash = "cash"
        case bank = "bank"
        case digital = "digital"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .card: return "Card"
            case .cash: return "Cash"
            case .bank: return "Bank Transfer"
            case .digital: return "Digital Wallet"
            case .other: return "Other"
            }
        }
        
        var defaultIcon: String {
            switch self {
            case .card: return "creditcard.fill"
            case .cash: return "banknote.fill"
            case .bank: return "building.columns.fill"
            case .digital: return "wallet.pass.fill"
            case .other: return "dollarsign.circle.fill"
            }
        }
    }
    
    var paymentType: PaymentType? {
        PaymentType(rawValue: type)
    }
}

#if DEBUG
extension SDPaymentMethod {
    static func mock(
        id: UUID = UUID(),
        name: String = "Credit Card",
        type: String = "card",
        icon: String = "creditcard.fill",
        color: String = "#2196F3",
        isActive: Bool = true,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) -> SDPaymentMethod {
        SDPaymentMethod(
            id: id,
            name: name,
            type: type,
            icon: icon,
            color: color,
            isActive: isActive,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
#endif
