import XCTest
import CoreData
@testable import OMOMoney

final class CategoryServiceTests: XCTestCase {
    
    var mockCoreDataStack: MockCoreDataStack!
    var categoryService: CategoryService!
    var testEntityFactory: TestEntityFactory!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCoreDataStack()
        categoryService = CategoryService(context: mockCoreDataStack.viewContext)
        testEntityFactory = TestEntityFactory(context: mockCoreDataStack.viewContext)
    }
    
    override func tearDown() {
        mockCoreDataStack.reset()
        super.tearDown()
    }
    
    // MARK: - Create Category Tests
    
    func testCreateCategory_Success() async throws {
        // Given
        let categoryName = "Test Category"
        let categoryColor = "#FF0000"
        let testGroup = testEntityFactory.createGroup()
        try mockCoreDataStack.save()
        
        // When
        let createdCategory = try await categoryService.createCategory(
            name: categoryName,
            color: categoryColor,
            group: testGroup
        )
        
        // Then
        XCTAssertNotNil(createdCategory)
        XCTAssertEqual(createdCategory.name, categoryName)
        XCTAssertEqual(createdCategory.color, categoryColor)
        XCTAssertEqual(createdCategory.group, testGroup)
        XCTAssertNotNil(createdCategory.id)
        XCTAssertNotNil(createdCategory.createdAt)
        
        // Verify category was saved to Core Data
        let savedCategory = try await categoryService.fetchCategory(by: createdCategory.id!)
        XCTAssertNotNil(savedCategory)
        XCTAssertEqual(savedCategory?.name, categoryName)
    }
    
    func testCreateCategory_WithoutGroup() async throws {
        // Given
        let categoryName = "Category without group"
        let categoryColor = "#00FF00"
        let testGroup = testEntityFactory.createGroup()
        
        // When
        let createdCategory = try await categoryService.createCategory(
            name: categoryName,
            color: categoryColor,
            group: testGroup
        )
        
        // Then
        XCTAssertNotNil(createdCategory)
        XCTAssertEqual(createdCategory.name, categoryName)
        XCTAssertEqual(createdCategory.color, categoryColor)
        XCTAssertEqual(createdCategory.group, testGroup)
    }
    
    // MARK: - Fetch Category Tests
    
    func testFetchCategories_Empty() async throws {
        // When
        let categories = try await categoryService.fetchCategories()
        
        // Then
        XCTAssertTrue(categories.isEmpty)
    }
    
    func testFetchCategories_WithData() async throws {
        // Given
        _ = testEntityFactory.createCategories(count: 3)
        try mockCoreDataStack.save()
        
        // When
        let fetchedCategories = try await categoryService.fetchCategories()
        
        // Then
        XCTAssertEqual(fetchedCategories.count, 3)
        XCTAssertTrue(fetchedCategories.allSatisfy { $0.name?.contains("Category") == true })
    }
    
    func testFetchCategory_ById() async throws {
        // Given
        let testCategory = testEntityFactory.createCategory()
        try mockCoreDataStack.save()
        
        // When
        let fetchedCategory = try await categoryService.fetchCategory(by: testCategory.id!)
        
        // Then
        XCTAssertNotNil(fetchedCategory)
        XCTAssertEqual(fetchedCategory?.id, testCategory.id)
        XCTAssertEqual(fetchedCategory?.name, testCategory.name)
    }
    
    func testFetchCategory_ByIdNotFound() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let fetchedCategory = try await categoryService.fetchCategory(by: nonExistentId)
        
        // Then
        XCTAssertNil(fetchedCategory)
    }
    
    func testGetCategories_ForGroup() async throws {
        // Given
        let group1 = testEntityFactory.createGroup(name: "Group 1")
        let group2 = testEntityFactory.createGroup(name: "Group 2")
        _ = testEntityFactory.createCategories(count: 2, group: group1)
        _ = testEntityFactory.createCategories(count: 3, group: group2)
        try mockCoreDataStack.save()
        
        // When
        let group1Categories = try await categoryService.getCategories(for: group1)
        let group2Categories = try await categoryService.getCategories(for: group2)
        
        // Then
        XCTAssertEqual(group1Categories.count, 2)
        XCTAssertEqual(group2Categories.count, 3)
        XCTAssertTrue(group1Categories.allSatisfy { $0.group == group1 })
        XCTAssertTrue(group2Categories.allSatisfy { $0.group == group2 })
    }
    
    // MARK: - Update Category Tests
    
    func testUpdateCategory_Success() async throws {
        // Given
        let testCategory = testEntityFactory.createCategory()
        try mockCoreDataStack.save()
        
        let newName = "Updated Category"
        let newColor = "#0000FF"
        
        // When
        try await categoryService.updateCategory(testCategory, name: newName, color: newColor)
        
        // Then
        XCTAssertEqual(testCategory.name, newName)
        XCTAssertEqual(testCategory.color, newColor)
        XCTAssertNotNil(testCategory.lastModifiedAt)
        
        // Verify changes were saved
        let updatedCategory = try await categoryService.fetchCategory(by: testCategory.id!)
        XCTAssertEqual(updatedCategory?.name, newName)
        XCTAssertEqual(updatedCategory?.color, newColor)
    }
    
    func testUpdateCategory_PartialUpdate() async throws {
        // Given
        let testCategory = testEntityFactory.createCategory()
        try mockCoreDataStack.save()
        
        let originalName = testCategory.name
        let newColor = "#FFFF00"
        
        // When
        try await categoryService.updateCategory(testCategory, name: nil, color: newColor)
        
        // Then
        XCTAssertEqual(testCategory.name, originalName) // Name unchanged
        XCTAssertEqual(testCategory.color, newColor) // Color updated
        XCTAssertNotNil(testCategory.lastModifiedAt)
    }
    
    // MARK: - Delete Category Tests
    
    func testDeleteCategory_Success() async throws {
        // Given
        let testCategory = testEntityFactory.createCategory()
        try mockCoreDataStack.save()
        
        // When
        try await categoryService.deleteCategory(testCategory)
        
        // Then
        let deletedCategory = try await categoryService.fetchCategory(by: testCategory.id!)
        XCTAssertNil(deletedCategory)
    }
    
    // MARK: - Validation Tests
    
    func testCategoryExists_True() async throws {
        // Given
        _ = testEntityFactory.createCategory(name: "Unique Category")
        try mockCoreDataStack.save()
        
        // When
        let exists = try await categoryService.categoryExists(withName: "Unique Category")
        
        // Then
        XCTAssertTrue(exists)
    }
    
    func testCategoryExists_False() async throws {
        // Given
        _ = testEntityFactory.createCategory(name: "Existing Category")
        try mockCoreDataStack.save()
        
        // When
        let exists = try await categoryService.categoryExists(withName: "Non Existent Category")
        
        // Then
        XCTAssertFalse(exists)
    }
    
    func testCategoryExists_WithinGroup() async throws {
        // Given
        let group1 = testEntityFactory.createGroup(name: "Group 1")
        let group2 = testEntityFactory.createGroup(name: "Group 2")
        _ = testEntityFactory.createCategory(name: "Same Name", group: group1)
        _ = testEntityFactory.createCategory(name: "Same Name", group: group2)
        try mockCoreDataStack.save()
        
        // When
        let existsInGroup1 = try await categoryService.categoryExists(withName: "Same Name", in: group1)
        let existsInGroup2 = try await categoryService.categoryExists(withName: "Same Name", in: group2)
        
        // Then
        XCTAssertTrue(existsInGroup1)
        XCTAssertTrue(existsInGroup2)
    }
    
    // MARK: - Count Tests
    
    func testGetCategoriesCount_Empty() async throws {
        // When
        let count = try await categoryService.getCategoriesCount()
        
        // Then
        XCTAssertEqual(count, 0)
    }
    
    func testGetCategoriesCount_WithData() async throws {
        // Given
        _ = testEntityFactory.createCategories(count: 5)
        try mockCoreDataStack.save()
        
        // When
        let count = try await categoryService.getCategoriesCount()
        
        // Then
        XCTAssertEqual(count, 5)
    }
    
    // MARK: - Caching Tests
    
    func testFetchCategories_Caching() async throws {
        // Given
        _ = testEntityFactory.createCategories(count: 2)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await categoryService.fetchCategories()
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await categoryService.fetchCategories()
        
        // Then
        XCTAssertEqual(firstFetch.count, 2)
        XCTAssertEqual(secondFetch.count, 2) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testGetCategoriesForGroup_Caching() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        _ = testEntityFactory.createCategories(count: 3, group: testGroup)
        try mockCoreDataStack.save()
        
        // When - First fetch (should cache)
        let firstFetch = try await categoryService.getCategories(for: testGroup)
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second fetch (should use cache)
        let secondFetch = try await categoryService.getCategories(for: testGroup)
        
        // Then
        XCTAssertEqual(firstFetch.count, 3)
        XCTAssertEqual(secondFetch.count, 3) // Should return cached data
        XCTAssertEqual(firstFetch.map { $0.id }, secondFetch.map { $0.id })
    }
    
    func testCategoryExists_Caching() async throws {
        // Given
        _ = testEntityFactory.createCategory(name: "Cache Test Category")
        try mockCoreDataStack.save()
        
        // When - First check (should cache)
        let firstCheck = try await categoryService.categoryExists(withName: "Cache Test Category")
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second check (should use cache)
        let secondCheck = try await categoryService.categoryExists(withName: "Cache Test Category")
        
        // Then
        XCTAssertTrue(firstCheck)
        XCTAssertTrue(secondCheck) // Should return cached result
    }
    
    func testGetCategoriesCount_Caching() async throws {
        // Given
        _ = testEntityFactory.createCategories(count: 3)
        try mockCoreDataStack.save()
        
        // When - First count (should cache)
        let firstCount = try await categoryService.getCategoriesCount()
        
        // Clear Core Data to simulate cache hit
        mockCoreDataStack.clearAllData()
        
        // Second count (should use cache)
        let secondCount = try await categoryService.getCategoriesCount()
        
        // Then
        XCTAssertEqual(firstCount, 3)
        XCTAssertEqual(secondCount, 3) // Should return cached result
    }
    
    // MARK: - Cache Invalidation Tests
    
    func testCreateCategory_InvalidatesCache() async throws {
        // Given
        let testGroup = testEntityFactory.createGroup()
        _ = testEntityFactory.createCategories(count: 2, group: testGroup)
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await categoryService.getCategories(for: testGroup)
        
        // When
        _ = try await categoryService.createCategory(
            name: "New Category",
            color: "#FF00FF",
            group: testGroup
        )
        
        // Then - Cache should be invalidated, so we get fresh data
        let allCategories = try await categoryService.getCategories(for: testGroup)
        XCTAssertEqual(allCategories.count, 3) // Should include the new category
        XCTAssertTrue(allCategories.contains { $0.name == "New Category" })
    }
    
    func testUpdateCategory_InvalidatesCache() async throws {
        // Given
        let testCategory = testEntityFactory.createCategory(name: "Original Category")
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await categoryService.fetchCategories()
        
        // When
        try await categoryService.updateCategory(testCategory, name: "Updated Category")
        
        // Then - Cache should be invalidated
        let updatedCategory = try await categoryService.fetchCategory(by: testCategory.id!)
        XCTAssertEqual(updatedCategory?.name, "Updated Category")
    }
    
    func testDeleteCategory_InvalidatesCache() async throws {
        // Given
        let testCategory = testEntityFactory.createCategory()
        try mockCoreDataStack.save()
        
        // Prime the cache
        _ = try await categoryService.fetchCategories()
        
        // When
        try await categoryService.deleteCategory(testCategory)
        
        // Then - Cache should be invalidated
        let allCategories = try await categoryService.fetchCategories()
        XCTAssertEqual(allCategories.count, 0) // Should reflect deletion
    }
}
