import Foundation
import SwiftData

@Model
final class SDCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String
    var icon: String
    var sortOrder: Int
    var limit: Double?
    var limitFrequency: String
    var createdAt: Date
    var lastModifiedAt: Date?
    
    var group: SDGroup?
    
    @Relationship(deleteRule: .nullify, inverse: \SDItemList.category)
    var itemLists: [SDItemList] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        color: String = "#8E8E93",
        icon: String = "tag.fill",
        sortOrder: Int = 0,
        limit: Double? = nil,
        limitFrequency: String = "monthly",
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.sortOrder = sortOrder
        self.limit = limit
        self.limitFrequency = limitFrequency
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }
}

extension SDCategory: Identifiable {}

extension SDCategory {
    var isValid: Bool {
        !name.isEmpty
    }
    
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyCategoryName
        }
    }
}

extension SDCategory {
    var hasLimit: Bool {
        limit != nil && limit! > 0
    }
    
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
    
    var isOverLimit: Bool {
        guard let limit = limit, limit > 0 else { return false }
        return totalSpent() > limit
    }
    
    var limitUsagePercentage: Double {
        guard let limit = limit, limit > 0 else { return 0 }
        return (totalSpent() / limit) * 100
    }
    
    enum Timeframe {
        case thisWeek
        case thisMonth
        case thisYear
        case allTime
    }
}

#if DEBUG
extension SDCategory {
    static func mock(
        id: UUID = UUID(),
        name: String = "Groceries",
        color: String = "#FF6B6B",
        icon: String = "cart.fill",
        limit: Double? = 500.0,
        limitFrequency: String = "monthly",
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) -> SDCategory {
        SDCategory(
            id: id,
            name: name,
            color: color,
            icon: icon,
            limit: limit,
            limitFrequency: limitFrequency,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
#endif
