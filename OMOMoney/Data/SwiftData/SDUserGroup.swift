import Foundation
import SwiftData

@Model
final class SDUserGroup {
    @Attribute(.unique) var id: UUID
    var role: String
    var joinedAt: Date
    
    var user: SDUser?
    var group: SDGroup?
    
    init(
        id: UUID = UUID(),
        role: String = "owner",
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.joinedAt = joinedAt
    }
}

extension SDUserGroup: Identifiable {}

extension SDUserGroup {
    enum Role: String, CaseIterable {
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
    
    var roleType: Role? {
        Role(rawValue: role)
    }
    
    func hasPermission(_ permission: Permission) -> Bool {
        guard let roleType = roleType else { return false }
        return roleType.permissions.contains(permission)
    }
    
    var isOwner: Bool {
        role == Role.owner.rawValue
    }
    
    var isAdminOrOwner: Bool {
        role == Role.owner.rawValue || role == Role.admin.rawValue
    }
}

extension SDUserGroup {
    var isValid: Bool {
        !role.isEmpty && user != nil && group != nil
    }
    
    func validate() throws {
        guard !role.isEmpty else {
            throw ValidationError.invalidRole
        }
        
        guard user != nil else {
            throw ValidationError.emptyName
        }
        
        guard group != nil else {
            throw ValidationError.invalidGroup
        }
    }
}

#if DEBUG
extension SDUserGroup {
    static func mock(
        id: UUID = UUID(),
        role: String = "owner",
        joinedAt: Date = Date(),
        user: SDUser? = nil,
        group: SDGroup? = nil
    ) -> SDUserGroup {
        let userGroup = SDUserGroup(
            id: id,
            role: role,
            joinedAt: joinedAt
        )
        userGroup.user = user
        userGroup.group = group
        return userGroup
    }
}
#endif
