//
//  CategoryDomain.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Pure Swift domain model for Category
/// No Core Data dependencies - represents business logic
struct CategoryDomain: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let color: String
    let limit: Decimal?
    let limitFrequency: String
    let groupId: UUID?
    let createdAt: Date
    let lastModifiedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        color: String = "#8E8E93",
        limit: Decimal? = nil,
        limitFrequency: String = "monthly",
        groupId: UUID? = nil,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.limit = limit
        self.limitFrequency = limitFrequency
        self.groupId = groupId
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }
}

// MARK: - Validation
extension CategoryDomain {
    var isValid: Bool {
        !name.isEmpty
    }
    
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyCategoryName
        }
    }
}

// MARK: - Test Mock
#if DEBUG
extension CategoryDomain {
    static func mock(
        id: UUID = UUID(),
        name: String = "Groceries",
        color: String = "#FF6B6B",
        limit: Decimal? = 500.0,
        limitFrequency: String = "monthly",
        groupId: UUID? = nil,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) -> CategoryDomain {
        CategoryDomain(
            id: id,
            name: name,
            color: color,
            limit: limit,
            limitFrequency: limitFrequency,
            groupId: groupId,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
#endif
