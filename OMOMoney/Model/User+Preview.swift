//
//  User+Preview.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

extension User {
    /// Creates a sample user for SwiftUI previews
    static func sampleUser(context: NSManagedObjectContext) -> User {
        let user = User(context: context, name: "John Doe", email: "john@example.com")
        user.id = UUID()
        user.createdAt = Date().addingTimeInterval(-86400) // 1 day ago
        user.lastModifiedAt = Date()
        return user
    }
    
    /// Creates multiple sample users for SwiftUI previews
    static func sampleUsers(context: NSManagedObjectContext) -> [User] {
        let names = ["Alice Smith", "Bob Johnson", "Carol Davis", "David Wilson"]
        let emails = ["alice@example.com", "bob@example.com", "carol@example.com", "david@example.com"]
        
        return zip(names, emails).enumerated().map { index, data in
            let user = User(context: context, name: data.0, email: data.1)
            user.id = UUID()
            user.createdAt = Date().addingTimeInterval(-Double(index * 86400)) // Different creation dates
            user.lastModifiedAt = Date()
            return user
        }
    }
}
