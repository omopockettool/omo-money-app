import Foundation
import SwiftData

@Model
final class SDUser {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String
    var createdAt: Date
    var lastModifiedAt: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \SDUserGroup.user)
    var userGroups: [SDUserGroup] = []
    
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

extension SDUser: Identifiable {}

extension SDUser {
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

extension SDUser {
    var groups: [SDGroup] {
        userGroups.compactMap { $0.group }
    }
    
    var isOwnerOfAnyGroup: Bool {
        userGroups.contains { $0.role == SDUserGroup.Role.owner.rawValue }
    }
}

#if DEBUG
extension SDUser {
    static func mock(
        id: UUID = UUID(),
        name: String = "John Doe",
        email: String = "john@example.com",
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) -> SDUser {
        SDUser(
            id: id,
            name: name,
            email: email,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
#endif
