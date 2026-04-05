//
//  MockUserGroupRepository.swift
//  OMOMoneyTests
//
//  Created on 11/18/25.
//

import Foundation
@testable import OMOMoney

/// Mock implementation of UserGroupRepository for testing
final class MockUserGroupRepository: UserGroupRepository {
    
    // MARK: - Tracking Properties
    
    var fetchUserGroupsCalled = false
    var fetchUserGroupCalled = false
    var createUserGroupCalled = false
    var updateUserGroupCalled = false
    var deleteUserGroupCalled = false
    var fetchUserGroupsForUserCalled = false
    var fetchUserGroupsForGroupCalled = false
    
    var lastCreatedUserId: UUID?
    var lastCreatedGroupId: UUID?
    var lastCreatedRole: String?
    var lastUpdatedUserGroup: UserGroupDomain?
    var lastDeletedUserGroupId: UUID?
    
    // MARK: - Mock Data
    
    var userGroupsToReturn: [UserGroupDomain] = []
    var userGroupToReturn: UserGroupDomain?
    var errorToThrow: Error?
    
    // MARK: - UserGroupRepository Implementation
    
    func fetchUserGroups() async throws -> [UserGroupDomain] {
        fetchUserGroupsCalled = true
        
        if let error = errorToThrow {
            throw error
        }
        
        return userGroupsToReturn
    }
    
    func fetchUserGroup(id: UUID) async throws -> UserGroupDomain? {
        fetchUserGroupCalled = true
        
        if let error = errorToThrow {
            throw error
        }
        
        return userGroupToReturn ?? userGroupsToReturn.first { $0.id == id }
    }
    
    func fetchUserGroups(forUserId userId: UUID) async throws -> [UserGroupDomain] {
        fetchUserGroupsForUserCalled = true
        
        if let error = errorToThrow {
            throw error
        }
        
        return userGroupsToReturn.filter { $0.userId == userId }
    }
    
    func fetchUserGroups(forGroupId groupId: UUID) async throws -> [UserGroupDomain] {
        fetchUserGroupsForGroupCalled = true
        
        if let error = errorToThrow {
            throw error
        }
        
        return userGroupsToReturn.filter { $0.groupId == groupId }
    }
    
    func createUserGroup(userId: UUID, groupId: UUID, role: String) async throws -> UserGroupDomain {
        createUserGroupCalled = true
        lastCreatedUserId = userId
        lastCreatedGroupId = groupId
        lastCreatedRole = role
        
        if let error = errorToThrow {
            throw error
        }
        
        let userGroup = UserGroupDomain(
            userId: userId,
            groupId: groupId,
            role: role
        )
        userGroupsToReturn.append(userGroup)
        return userGroup
    }
    
    func updateUserGroup(_ userGroup: UserGroupDomain) async throws {
        updateUserGroupCalled = true
        lastUpdatedUserGroup = userGroup
        
        if let error = errorToThrow {
            throw error
        }
        
        // Update in mock data
        if let index = userGroupsToReturn.firstIndex(where: { $0.id == userGroup.id }) {
            userGroupsToReturn[index] = userGroup
        }
    }
    
    func deleteUserGroup(id: UUID) async throws {
        deleteUserGroupCalled = true
        lastDeletedUserGroupId = id
        
        if let error = errorToThrow {
            throw error
        }
        
        // Remove from mock data
        userGroupsToReturn.removeAll { $0.id == id }
    }
    
    func removeUser(_ userId: UUID, fromGroup groupId: UUID) async throws {
        deleteUserGroupCalled = true
        
        if let error = errorToThrow {
            throw error
        }
        
        // Remove from mock data
        userGroupsToReturn.removeAll { $0.userId == userId && $0.groupId == groupId }
    }
    
    // MARK: - Helper Methods
    
    func reset() {
        fetchUserGroupsCalled = false
        fetchUserGroupCalled = false
        createUserGroupCalled = false
        updateUserGroupCalled = false
        deleteUserGroupCalled = false
        fetchUserGroupsForUserCalled = false
        fetchUserGroupsForGroupCalled = false
        
        lastCreatedUserId = nil
        lastCreatedGroupId = nil
        lastCreatedRole = nil
        lastUpdatedUserGroup = nil
        lastDeletedUserGroupId = nil
        
        userGroupsToReturn = []
        userGroupToReturn = nil
        errorToThrow = nil
    }
}
