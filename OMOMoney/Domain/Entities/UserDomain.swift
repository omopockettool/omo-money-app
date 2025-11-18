//
//  UserDomain.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Pure Swift domain model for User
/// No Core Data dependencies - represents business logic
struct UserDomain: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let email: String
    let createdAt: Date
    let lastModifiedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }
}

// MARK: - Validation
extension UserDomain {
    var isValid: Bool {
        !name.isEmpty && !email.isEmpty && email.contains("@")
    }
    
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyName
        }
        
        guard !email.isEmpty else {
            throw ValidationError.emptyEmail
        }
        
        guard email.contains("@") else {
            throw ValidationError.invalidEmail
        }
    }
}

// MARK: - Validation Errors
enum ValidationError: LocalizedError {
    case emptyName
    case emptyEmail
    case invalidEmail
    case emptyGroupName
    case invalidAmount
    case emptyItemDescription
    case emptyCategoryName
    case emptyPaymentMethodName
    
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Name cannot be empty"
        case .emptyEmail:
            return "Email cannot be empty"
        case .invalidEmail:
            return "Email must be valid"
        case .emptyGroupName:
            return "Group name cannot be empty"
        case .invalidAmount:
            return "Amount must be greater than zero"
        case .emptyItemDescription:
            return "Item description cannot be empty"
        case .emptyCategoryName:
            return "Category name cannot be empty"
        case .emptyPaymentMethodName:
            return "Payment method name cannot be empty"
        }
    }
}

// MARK: - Test Mock
#if DEBUG
extension UserDomain {
    static func mock(
        id: UUID = UUID(),
        name: String = "John Doe",
        email: String = "john@example.com",
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) -> UserDomain {
        UserDomain(
            id: id,
            name: name,
            email: email,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
#endif
