//
//  CreateFirstUserViewModelTests.swift
//  OMOMoneyTests
//
//  Created on 11/18/25.
//

import XCTest
@testable import OMOMoney

@MainActor
final class CreateFirstUserViewModelTests: XCTestCase {
    
    private var mockUserRepository: MockUserRepository!
    private var mockGroupRepository: MockGroupRepository!
    private var mockUserGroupRepository: MockUserGroupRepository!
    private var createUserUseCase: CreateUserUseCase!
    private var createGroupUseCase: CreateGroupUseCase!
    private var createUserGroupUseCase: CreateUserGroupUseCase!
    private var viewModel: CreateFirstUserViewModel!
    
    override func setUp() {
        super.setUp()
        
        // Setup mocks
        mockUserRepository = MockUserRepository()
        mockGroupRepository = MockGroupRepository()
        mockUserGroupRepository = MockUserGroupRepository()
        
        // Setup use cases
        createUserUseCase = DefaultCreateUserUseCase(userRepository: mockUserRepository)
        createGroupUseCase = DefaultCreateGroupUseCase(groupRepository: mockGroupRepository)
        createUserGroupUseCase = DefaultCreateUserGroupUseCase(userGroupRepository: mockUserGroupRepository)
        
        // Setup ViewModel
        viewModel = CreateFirstUserViewModel(
            createUserUseCase: createUserUseCase,
            createGroupUseCase: createGroupUseCase,
            createUserGroupUseCase: createUserGroupUseCase
        )
    }
    
    override func tearDown() {
        viewModel = nil
        createUserUseCase = nil
        createGroupUseCase = nil
        createUserGroupUseCase = nil
        mockUserRepository = nil
        mockGroupRepository = nil
        mockUserGroupRepository = nil
        super.tearDown()
    }
    
    // MARK: - Form Validation Tests
    
    func testIsFormValid_WithValidData_ReturnsTrue() {
        // Given
        viewModel.name = "John Doe"
        viewModel.email = "john@example.com"
        
        // When/Then
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    func testIsFormValid_WithEmptyName_ReturnsFalse() {
        // Given
        viewModel.name = ""
        viewModel.email = "john@example.com"
        
        // When/Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func testIsFormValid_WithEmptyEmail_ReturnsFalse() {
        // Given
        viewModel.name = "John Doe"
        viewModel.email = ""
        
        // When/Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func testIsFormValid_WithInvalidEmail_ReturnsFalse() {
        // Given
        viewModel.name = "John Doe"
        viewModel.email = "invalidemail"
        
        // When/Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func testIsFormValid_WithWhitespaceOnlyName_ReturnsFalse() {
        // Given
        viewModel.name = "   "
        viewModel.email = "john@example.com"
        
        // When/Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    // MARK: - Create User Tests
    
    func testCreateUser_WithValidData_Success() async {
        // Given
        viewModel.name = "John Doe"
        viewModel.email = "john@example.com"
        
        // When
        await viewModel.createUser()
        
        // Then
        XCTAssertTrue(mockUserRepository.createUserCalled)
        XCTAssertTrue(mockGroupRepository.createGroupCalled)
        XCTAssertEqual(mockUserRepository.lastCreatedName, "John Doe")
        XCTAssertEqual(mockUserRepository.lastCreatedEmail, "john@example.com")
        XCTAssertEqual(mockGroupRepository.lastCreatedName, "Personal")
        XCTAssertEqual(mockGroupRepository.lastCreatedCurrency, "USD")
        XCTAssertTrue(viewModel.isSuccess)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testCreateUser_WithInvalidForm_DoesNotCreate() async {
        // Given
        viewModel.name = ""
        viewModel.email = "john@example.com"
        
        // When
        await viewModel.createUser()
        
        // Then
        XCTAssertFalse(mockUserRepository.createUserCalled)
        XCTAssertFalse(mockGroupRepository.createGroupCalled)
        XCTAssertFalse(viewModel.isSuccess)
    }
    
    func testCreateUser_WithEmptyName_ShowsError() async {
        // Given
        viewModel.name = ""
        viewModel.email = "john@example.com"
        mockUserRepository.errorToThrow = ValidationError.emptyName
        
        // When
        await viewModel.createUser()
        
        // Then
        XCTAssertFalse(viewModel.isSuccess)
    }
    
    func testCreateUser_TrimsWhitespace() async {
        // Given
        viewModel.name = "  John Doe  "
        viewModel.email = "  john@example.com  "
        
        // When
        await viewModel.createUser()
        
        // Then
        XCTAssertEqual(mockUserRepository.lastCreatedName, "John Doe")
        XCTAssertEqual(mockUserRepository.lastCreatedEmail, "john@example.com")
    }
    
    func testCreateUser_OnError_ShowsErrorMessage() async {
        // Given
        viewModel.name = "John Doe"
        viewModel.email = "john@example.com"
        mockUserRepository.errorToThrow = RepositoryError.saveFailed
        
        // When
        await viewModel.createUser()
        
        // Then
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSuccess)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testCreateUser_SetsLoadingState() async {
        // Given
        viewModel.name = "John Doe"
        viewModel.email = "john@example.com"
        
        // When
        let expectation = XCTestExpectation(description: "Loading state")
        
        Task {
            XCTAssertFalse(viewModel.isLoading) // Before
            
            await viewModel.createUser()
            
            XCTAssertFalse(viewModel.isLoading) // After
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Clear Form Tests
    
    func testClearForm_ResetsAllFields() {
        // Given
        viewModel.name = "John Doe"
        viewModel.email = "john@example.com"
        viewModel.errorMessage = "Some error"
        viewModel.showError = true
        
        // When
        viewModel.clearForm()
        
        // Then
        XCTAssertEqual(viewModel.name, "")
        XCTAssertEqual(viewModel.email, "")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
}
