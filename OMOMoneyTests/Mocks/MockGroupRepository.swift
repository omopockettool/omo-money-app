//
//  MockGroupRepository.swift
//  OMOMoneyTests
//
//  Created on 11/18/25.
//

import Foundation
@testable import OMOMoney

/// Mock implementation of GroupRepository for testing
final class MockGroupRepository: GroupRepository {
    
    // MARK: - Tracking Properties
    
    var fetchGroupsCalled = false
    var fetchGroupCalled = false
    var createGroupCalled = false
    var updateGroupCalled = false
    var deleteGroupCalled = false
    var fetchGroupsForUserCalled = false
    
    var lastCreatedName: String?
    var lastCreatedCurrency: String?
    var lastUpdatedGroup: GroupDomain?
    var lastDeletedGroupId: UUID?
    var lastFetchedUserId: UUID?
    
    // MARK: - Mock Data
    
    var groupsToReturn: [GroupDomain] = []
    var groupToReturn: GroupDomain?
    var errorToThrow: Error?
    
    // MARK: - GroupRepository Implementation
    
    func fetchGroups() async throws -> [GroupDomain] {
        fetchGroupsCalled = true
        
        if let error = errorToThrow {
            throw error
        }
        
        return groupsToReturn
    }
    
    func fetchGroup(id: UUID) async throws -> GroupDomain? {
        fetchGroupCalled = true
        
        if let error = errorToThrow {
            throw error
        }
        
        return groupToReturn ?? groupsToReturn.first { $0.id == id }
    }
    
    func createGroup(name: String, currency: String) async throws -> GroupDomain {
        createGroupCalled = true
        lastCreatedName = name
        lastCreatedCurrency = currency
        
        if let error = errorToThrow {
            throw error
        }
        
        let group = GroupDomain(name: name, currency: currency)
        groupsToReturn.append(group)
        return group
    }
    
    func updateGroup(_ group: GroupDomain) async throws {
        updateGroupCalled = true
        lastUpdatedGroup = group
        
        if let error = errorToThrow {
            throw error
        }
        
        // Update in mock data
        if let index = groupsToReturn.firstIndex(where: { $0.id == group.id }) {
            groupsToReturn[index] = group
        }
    }
    
    func deleteGroup(id: UUID) async throws {
        deleteGroupCalled = true
        lastDeletedGroupId = id
        
        if let error = errorToThrow {
            throw error
        }
        
        groupsToReturn.removeAll { $0.id == id }
    }
    
    func fetchGroups(forUserId userId: UUID) async throws -> [GroupDomain] {
        fetchGroupsForUserCalled = true
        lastFetchedUserId = userId
        
        if let error = errorToThrow {
            throw error
        }
        
        return groupsToReturn
    }
    
    // MARK: - Helper Methods
    
    func reset() {
        fetchGroupsCalled = false
        fetchGroupCalled = false
        createGroupCalled = false
        updateGroupCalled = false
        deleteGroupCalled = false
        fetchGroupsForUserCalled = false
        
        lastCreatedName = nil
        lastCreatedCurrency = nil
        lastUpdatedGroup = nil
        lastDeletedGroupId = nil
        lastFetchedUserId = nil
        
        groupsToReturn = []
        groupToReturn = nil
        errorToThrow = nil
    }
}
