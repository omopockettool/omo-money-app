//
//  CreateUserUseCaseTests.swift
//  OMOMoneyTests
//
//  Created on 11/18/25.
//

import XCTest
@testable import OMOMoney

final class CreateUserUseCaseTests: XCTestCase {
    
    private var mockRepository: MockUserRepository!
    private var useCase: CreateUserUseCase!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        useCase = DefaultCreateUserUseCase(userRepository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        useCase = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    
    func testCreateUser_WithValidData_ReturnsUser() async throws {
        // Given
        let name = "John Doe"
        let email = "john@example.com"
        
        // When
        let user = try await useCase.execute(name: name, email: email)
        
        // Then
        XCTAssertTrue(mockRepository.createUserCalled)
        XCTAssertEqual(user.name, name)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(mockRepository.lastCreatedName, name)
        XCTAssertEqual(mockRepository.lastCreatedEmail, email)
    }
    
    func testCreateUser_TrimsWhitespace_ReturnsCleanedUser() async throws {
        // Given
        let name = "  John Doe  "
        let email = "  john@example.com  "
        
        // When
        let user = try await useCase.execute(name: name, email: email)
        
        // Then
        XCTAssertEqual(user.name, "John Doe")
        XCTAssertEqual(user.email, "john@example.com")
    }
    
    // MARK: - Validation Failure Cases
    
    func testCreateUser_WithEmptyName_ThrowsError() async {
        // Given
        let name = ""
        let email = "john@example.com"
        
        // When/Then
        do {
            _ = try await useCase.execute(name: name, email: email)
            XCTFail("Expected ValidationError.emptyName to be thrown")
        } catch let error as ValidationError {
            XCTAssertEqual(error, ValidationError.emptyName)
        } catch {
            XCTFail("Expected ValidationError.emptyName but got \(error)")
        }
    }
    
    func testCreateUser_WithEmptyEmail_ThrowsError() async {
        // Given
        let name = "John Doe"
        let email = ""
        
        // When/Then
        do {
            _ = try await useCase.execute(name: name, email: email)
            XCTFail("Expected ValidationError.emptyEmail to be thrown")
        } catch let error as ValidationError {
            XCTAssertEqual(error, ValidationError.emptyEmail)
        } catch {
            XCTFail("Expected ValidationError.emptyEmail but got \(error)")
        }
    }
    
    func testCreateUser_WithInvalidEmail_ThrowsError() async {
        // Given
        let name = "John Doe"
        let email = "invalidemail"
        
        // When/Then
        do {
            _ = try await useCase.execute(name: name, email: email)
            XCTFail("Expected ValidationError.invalidEmail to be thrown")
        } catch let error as ValidationError {
            XCTAssertEqual(error, ValidationError.invalidEmail)
        } catch {
            XCTFail("Expected ValidationError.invalidEmail but got \(error)")
        }
    }
    
    func testCreateUser_WithWhitespaceOnlyName_ThrowsError() async {
        // Given
        let name = "   "
        let email = "john@example.com"
        
        // When/Then
        do {
            _ = try await useCase.execute(name: name, email: email)
            XCTFail("Expected ValidationError.emptyName to be thrown")
        } catch let error as ValidationError {
            XCTAssertEqual(error, ValidationError.emptyName)
        } catch {
            XCTFail("Expected ValidationError.emptyName but got \(error)")
        }
    }
}
