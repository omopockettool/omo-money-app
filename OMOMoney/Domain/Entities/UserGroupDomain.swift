//
//  UserGroupDomain.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Pure Swift domain model for UserGroup (many-to-many relationship)
/// No Core Data dependencies - represents business logic
struct UserGroupDomain: Identifiable, Equatable, Hashable {
    let id: UUID
    let userId: UUID
    let groupId: UUID
    let role: String
    let joinedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        groupId: UUID,
        role: String = "owner",
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.groupId = groupId
        self.role = role
        self.joinedAt = joinedAt
    }
}

// MARK: - Role Types
extension UserGroupDomain {
    enum Role: String {
        case owner = "owner"
        case admin = "admin"
        case member = "member"
        
        var permissions: [Permission] {
            switch self {
            case .owner:
                return Permission.allCases
            case .admin:
                return [.read, .write, .delete]
            case .member:
                return [.read, .write]
            }
        }
    }
    
    enum Permission: CaseIterable {
        case read
        case write
        case delete
        case manageUsers
    }
}

// MARK: - Test Mock
#if DEBUG
extension UserGroupDomain {
    static func mock(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        groupId: UUID = UUID(),
        role: String = "owner",
        joinedAt: Date = Date()
    ) -> UserGroupDomain {
        UserGroupDomain(
            id: id,
            userId: userId,
            groupId: groupId,
            role: role,
            joinedAt: joinedAt
        )
    }
}
#endif
