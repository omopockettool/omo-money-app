import Foundation
import SwiftData

@Model
final class SDGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var currency: String
    var createdAt: Date
    var lastModifiedAt: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \SDUserGroup.group)
    var userGroups: [SDUserGroup] = []
    
    @Relationship(deleteRule: .cascade, inverse: \SDCategory.group)
    var categories: [SDCategory] = []
    
    @Relationship(deleteRule: .cascade, inverse: \SDPaymentMethod.group)
    var paymentMethods: [SDPaymentMethod] = []
    
    @Relationship(deleteRule: .cascade, inverse: \SDItemList.group)
    var itemLists: [SDItemList] = []
    
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

extension SDGroup: Identifiable {}

extension SDGroup {
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

extension SDGroup {
    var users: [SDUser] {
        userGroups.compactMap { $0.user }
    }
    
    var owner: SDUser? {
        userGroups.first { $0.role == UserGroupDomain.Role.owner.rawValue }?.user
    }
    
    var activePaymentMethods: [SDPaymentMethod] {
        paymentMethods.filter { $0.isActive }
    }
    
    var defaultCategory: SDCategory? {
        categories.first { $0.isDefault }
    }
    
    var defaultPaymentMethod: SDPaymentMethod? {
        paymentMethods.first { $0.isDefault }
    }
}

#if DEBUG
extension SDGroup {
    static func mock(
        id: UUID = UUID(),
        name: String = "My Group",
        currency: String = "USD",
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) -> SDGroup {
        SDGroup(
            id: id,
            name: name,
            currency: currency,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
#endif
