//
//  GroupDomain.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Pure Swift domain model for Group
/// No Core Data dependencies - represents business logic
struct GroupDomain: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let currency: String
    let createdAt: Date
    let lastModifiedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        currency: String = "USD",
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.currency = currency
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }
}

// MARK: - Validation
extension GroupDomain {
    var isValid: Bool {
        !name.isEmpty && !currency.isEmpty
    }
    
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyGroupName
        }
        
        guard !currency.isEmpty else {
            throw ValidationError.invalidAmount
        }
    }
}

// MARK: - Test Mock
#if DEBUG
extension GroupDomain {
    static func mock(
        id: UUID = UUID(),
        name: String = "My Group",
        currency: String = "USD",
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) -> GroupDomain {
        GroupDomain(
            id: id,
            name: name,
            currency: currency,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
#endif
