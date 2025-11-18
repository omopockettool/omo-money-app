//
//  MockUserRepository.swift
//  OMOMoneyTests
//
//  Created on 11/18/25.
//

import Foundation
@testable import OMOMoney

/// Mock implementation of UserRepository for testing
final class MockUserRepository: UserRepository {
    
    // MARK: - Tracking Properties
    
    var fetchUsersCalled = false
    var fetchUserCalled = false
    var createUserCalled = false
    var updateUserCalled = false
    var deleteUserCalled = false
    var searchUsersCalled = false
    
    var lastCreatedName: String?
    var lastCreatedEmail: String?
    var lastUpdatedUser: UserDomain?
    var lastDeletedUserId: UUID?
    var lastSearchQuery: String?
    
    // MARK: - Mock Data
    
    var usersToReturn: [UserDomain] = []
    var userToReturn: UserDomain?
    var errorToThrow: Error?
    
    // MARK: - UserRepository Implementation
    
    func fetchUsers() async throws -> [UserDomain] {
        fetchUsersCalled = true
        
        if let error = errorToThrow {
            throw error
        }
        
        return usersToReturn
    }
    
    func fetchUser(id: UUID) async throws -> UserDomain? {
        fetchUserCalled = true
        
        if let error = errorToThrow {
            throw error
        }
        
        return userToReturn ?? usersToReturn.first { $0.id == id }
    }
    
    func createUser(name: String, email: String) async throws -> UserDomain {
        createUserCalled = true
        lastCreatedName = name
        lastCreatedEmail = email
        
        if let error = errorToThrow {
            throw error
        }
        
        let user = UserDomain(name: name, email: email)
        usersToReturn.append(user)
        return user
    }
    
    func updateUser(_ user: UserDomain) async throws {
        updateUserCalled = true
        lastUpdatedUser = user
        
        if let error = errorToThrow {
            throw error
        }
        
        // Update in mock data
        if let index = usersToReturn.firstIndex(where: { $0.id == user.id }) {
            usersToReturn[index] = user
        }
    }
    
    func deleteUser(id: UUID) async throws {
        deleteUserCalled = true
        lastDeletedUserId = id
        
        if let error = errorToThrow {
            throw error
        }
        
        usersToReturn.removeAll { $0.id == id }
    }
    
    func searchUsers(query: String) async throws -> [UserDomain] {
        searchUsersCalled = true
        lastSearchQuery = query
        
        if let error = errorToThrow {
            throw error
        }
        
        return usersToReturn.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.email.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Helper Methods
    
    func reset() {
        fetchUsersCalled = false
        fetchUserCalled = false
        createUserCalled = false
        updateUserCalled = false
        deleteUserCalled = false
        searchUsersCalled = false
        
        lastCreatedName = nil
        lastCreatedEmail = nil
        lastUpdatedUser = nil
        lastDeletedUserId = nil
        lastSearchQuery = nil
        
        usersToReturn = []
        userToReturn = nil
        errorToThrow = nil
    }
}
