//
//  User+Safe.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

extension User {
    
    /// Safe count of user groups - with maximum safety
    var safeUserGroupsCount: Int {
        // Multiple safety checks to prevent any NaN values
        guard let userGroups = self.userGroups else { return 0 }
        guard self.id != nil else { return 0 }
        guard userGroups.count >= 0 else { return 0 }
        guard userGroups.count <= 1000 else { return 0 } // Reasonable upper limit
        
        return userGroups.count
    }
    
    /// Safe check if user has owner role in any group - with maximum safety
    var hasOwnerRole: Bool {
        // Multiple safety checks to prevent any NaN values
        guard let userGroups = self.userGroups else { return false }
        guard self.id != nil else { return false }
        guard userGroups.count > 0 else { return false }
        guard userGroups.count <= 1000 else { return false } // Reasonable upper limit
        
        // Safe iteration without any complex operations
        var ownerFound = false
        var iterationCount = 0
        let maxIterations = 1000 // Prevent infinite loops
        
        for case let userGroup as UserGroup in userGroups {
            iterationCount += 1
            if iterationCount > maxIterations { break }
            
            if let role = userGroup.role, role == "owner" {
                ownerFound = true
                break
            }
        }
        
        return ownerFound
    }
    
    /// Safe check if user has any groups - with maximum safety
    var hasGroups: Bool {
        // Multiple safety checks to prevent any NaN values
        guard let userGroups = self.userGroups else { return false }
        guard self.id != nil else { return false }
        guard userGroups.count > 0 else { return false }
        guard userGroups.count <= 1000 else { return false } // Reasonable upper limit
        
        return true
    }
    
    /// Safe array of user groups - with maximum safety
    var safeUserGroups: [UserGroup] {
        // Multiple safety checks to prevent any NaN values
        guard let userGroups = self.userGroups else { return [] }
        guard self.id != nil else { return [] }
        guard userGroups.count >= 0 else { return [] }
        guard userGroups.count <= 1000 else { return [] } // Reasonable upper limit
        
        var result: [UserGroup] = []
        var iterationCount = 0
        let maxIterations = 1000 // Prevent infinite loops
        
        for case let userGroup as UserGroup in userGroups {
            iterationCount += 1
            if iterationCount > maxIterations { break }
            
            // Additional safety check
            if userGroup.id != nil {
                result.append(userGroup)
            }
        }
        
        return result
    }
    
    /// Safe array of groups the user belongs to - with maximum safety
    var safeGroups: [Group] {
        // Multiple safety checks to prevent any NaN values
        guard let userGroups = self.userGroups else { return [] }
        guard self.id != nil else { return [] }
        guard userGroups.count >= 0 else { return [] }
        guard userGroups.count <= 1000 else { return [] } // Reasonable upper limit
        
        var result: [Group] = []
        var iterationCount = 0
        let maxIterations = 1000 // Prevent infinite loops
        
        for case let userGroup as UserGroup in userGroups {
            iterationCount += 1
            if iterationCount > maxIterations { break }
            
            if let group = userGroup.group, group.id != nil {
                result.append(group)
            }
        }
        
        return result
    }
    
    /// Safe array of roles the user has - with maximum safety
    var safeRoles: [String] {
        // Multiple safety checks to prevent any NaN values
        guard let userGroups = self.userGroups else { return [] }
        guard self.id != nil else { return [] }
        guard userGroups.count >= 0 else { return [] }
        guard userGroups.count <= 1000 else { return [] } // Reasonable upper limit
        
        var result: [String] = []
        var iterationCount = 0
        let maxIterations = 1000 // Prevent infinite loops
        
        for case let userGroup as UserGroup in userGroups {
            iterationCount += 1
            if iterationCount > maxIterations { break }
            
            if let role = userGroup.role, !role.isEmpty {
                result.append(role)
            }
        }
        
        return result
    }
}
