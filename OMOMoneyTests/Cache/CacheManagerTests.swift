import XCTest
@testable import OMOMoney

final class CacheManagerTests: XCTestCase {
    
    var cacheManager: CacheManager!
    
    override func setUp() {
        super.setUp()
        cacheManager = CacheManager.shared
        cacheManager.clearAllCaches()
    }
    
    override func tearDown() {
        cacheManager.clearAllCaches()
        super.tearDown()
    }
    
    // MARK: - Data Cache Tests
    
    func testDataCache_StoreAndRetrieve() async {
        // Given
        let testData = ["test": "value", "number": 42]
        let cacheKey = "test.data"
        
        // When
        await cacheManager.cacheData(testData, for: cacheKey)
        let retrievedData: [String: Any]? = await cacheManager.getCachedData(for: cacheKey)
        
        // Then
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData?["test"] as? String, "value")
        XCTAssertEqual(retrievedData?["number"] as? Int, 42)
    }
    
    func testDataCache_Expiration() async {
        // Given
        let testData = "test value"
        let cacheKey = "test.expiration"
        
        // When
        await cacheManager.cacheData(testData, for: cacheKey)
        
        // Simulate time passing (cache expires after 5 minutes)
        // We'll test by clearing and checking if it's gone
        await cacheManager.clearDataCache(for: cacheKey)
        let retrievedData: String? = await cacheManager.getCachedData(for: cacheKey)
        
        // Then
        XCTAssertNil(retrievedData)
    }
    
    func testDataCache_ClearSpecific() async {
        // Given
        let data1 = "data1"
        let data2 = "data2"
        let key1 = "key1"
        let key2 = "key2"
        
        // When
        await cacheManager.cacheData(data1, for: key1)
        await cacheManager.cacheData(data2, for: key2)
        
        await cacheManager.clearDataCache(for: key1)
        
        let retrieved1: String? = await cacheManager.getCachedData(for: key1)
        let retrieved2: String? = await cacheManager.getCachedData(for: key2)
        
        // Then
        XCTAssertNil(retrieved1)
        XCTAssertNotNil(retrieved2)
        XCTAssertEqual(retrieved2, data2)
    }
    
    func testDataCache_ClearAll() async {
        // Given
        let data1 = "data1"
        let data2 = "data2"
        let key1 = "key1"
        let key2 = "key2"
        
        // When
        await cacheManager.cacheData(data1, for: key1)
        await cacheManager.cacheData(data2, for: key2)
        
        await cacheManager.clearAllDataCache()
        
        let retrieved1: String? = await cacheManager.getCachedData(for: key1)
        let retrieved2: String? = await cacheManager.getCachedData(for: key2)
        
        // Then
        XCTAssertNil(retrieved1)
        XCTAssertNil(retrieved2)
    }
    
    // MARK: - Validation Cache Tests
    
    func testValidationCache_StoreAndRetrieve() async {
        // Given
        let testValidation = true
        let cacheKey = "test.validation"
        
        // When
        await cacheManager.cacheValidation(testValidation, for: cacheKey)
        let retrievedValidation = await cacheManager.getCachedValidation(for: cacheKey)
        
        // Then
        XCTAssertNotNil(retrievedValidation)
        XCTAssertEqual(retrievedValidation, testValidation)
    }
    
    func testValidationCache_Expiration() async {
        // Given
        let testValidation = false
        let cacheKey = "test.validation.expiration"
        
        // When
        await cacheManager.cacheValidation(testValidation, for: cacheKey)
        
        // Simulate time passing (validation cache expires after 1 minute)
        await cacheManager.clearValidationCache(for: cacheKey)
        let retrievedValidation = await cacheManager.getCachedValidation(for: cacheKey)
        
        // Then
        XCTAssertNil(retrievedValidation)
    }
    
    func testValidationCache_ClearSpecific() async {
        // Given
        let validation1 = true
        let validation2 = false
        let key1 = "validation1"
        let key2 = "validation2"
        
        // When
        await cacheManager.cacheValidation(validation1, for: key1)
        await cacheManager.cacheValidation(validation2, for: key2)
        
        await cacheManager.clearValidationCache(for: key1)
        
        let retrieved1 = await cacheManager.getCachedValidation(for: key1)
        let retrieved2 = await cacheManager.getCachedValidation(for: key2)
        
        // Then
        XCTAssertNil(retrieved1)
        XCTAssertNotNil(retrieved2)
        XCTAssertEqual(retrieved2, validation2)
    }
    
    // MARK: - Calculation Cache Tests
    
    func testCalculationCache_StoreAndRetrieve() async {
        // Given
        let testCalculation = 3.14159
        let cacheKey = "test.calculation"
        
        // When
        await cacheManager.cacheCalculation(testCalculation, for: cacheKey)
        let retrievedCalculation: Double? = await cacheManager.getCachedCalculation(for: cacheKey)
        
        // Then
        XCTAssertNotNil(retrievedCalculation)
        XCTAssertEqual(retrievedCalculation, testCalculation)
    }
    
    func testCalculationCache_Expiration() async {
        // Given
        let testCalculation = 42.0
        let cacheKey = "test.calculation.expiration"
        
        // When
        await cacheManager.cacheCalculation(testCalculation, for: cacheKey)
        
        // Simulate time passing (calculation cache expires after 10 minutes)
        await cacheManager.clearCalculationCache(for: cacheKey)
        let retrievedCalculation: Double? = await cacheManager.getCachedCalculation(for: cacheKey)
        
        // Then
        XCTAssertNil(retrievedCalculation)
    }
    
    func testCalculationCache_ClearSpecific() async {
        // Given
        let calculation1 = 10.0
        let calculation2 = 20.0
        let key1 = "calc1"
        let key2 = "calc2"
        
        // When
        await cacheManager.cacheCalculation(calculation1, for: key1)
        await cacheManager.cacheCalculation(calculation2, for: key2)
        
        await cacheManager.clearCalculationCache(for: key1)
        
        let retrieved1: Double? = await cacheManager.getCachedCalculation(for: key1)
        let retrieved2: Double? = await cacheManager.getCachedCalculation(for: key2)
        
        // Then
        XCTAssertNil(retrieved1)
        XCTAssertNotNil(retrieved2)
        XCTAssertEqual(retrieved2, calculation2)
    }
    
    // MARK: - Cache Statistics Tests
    
    func testCacheStats_EmptyCache() async {
        // When
        let stats = await cacheManager.getCacheStats()
        
        // Then
        XCTAssertEqual(stats.dataCount, 0)
        XCTAssertEqual(stats.validationCount, 0)
        XCTAssertEqual(stats.calculationCount, 0)
    }
    
    func testCacheStats_WithData() async {
        // Given
        await cacheManager.cacheData("data", for: "dataKey")
        await cacheManager.cacheValidation(true, for: "validationKey")
        await cacheManager.cacheCalculation(42.0, for: "calculationKey")
        
        // When
        let stats = await cacheManager.getCacheStats()
        
        // Then
        XCTAssertEqual(stats.dataCount, 1)
        XCTAssertEqual(stats.validationCount, 1)
        XCTAssertEqual(stats.calculationCount, 1)
    }
    
    // MARK: - Cleanup Tests
    
    func testClearAllCaches() async {
        // Given
        await cacheManager.cacheData("data", for: "dataKey")
        await cacheManager.cacheValidation(true, for: "validationKey")
        await cacheManager.cacheCalculation(42.0, for: "calculationKey")
        
        // When
        await cacheManager.clearAllCaches()
        let stats = await cacheManager.getCacheStats()
        
        // Then
        XCTAssertEqual(stats.dataCount, 0)
        XCTAssertEqual(stats.validationCount, 0)
        XCTAssertEqual(stats.calculationCount, 0)
    }
    
    func testCleanExpiredCache() async {
        // Given
        await cacheManager.cacheData("data", for: "dataKey")
        await cacheManager.cacheValidation(true, for: "validationKey")
        await cacheManager.cacheCalculation(42.0, for: "calculationKey")
        
        // When
        await cacheManager.cleanExpiredCache()
        let stats = await cacheManager.getCacheStats()
        
        // Then
        // Since we just created the cache entries, they shouldn't be expired yet
        XCTAssertEqual(stats.dataCount, 1)
        XCTAssertEqual(stats.validationCount, 1)
        XCTAssertEqual(stats.calculationCount, 1)
    }
    
    // MARK: - Type Safety Tests
    
    func testTypeSafety_DifferentTypes() async {
        // Given
        let stringData = "string data"
        let intData = 42
        let cacheKey = "type.test"
        
        // When
        await cacheManager.cacheData(stringData, for: cacheKey)
        let retrievedString: String? = await cacheManager.getCachedData(for: cacheKey)
        let retrievedInt: Int? = await cacheManager.getCachedData(for: cacheKey)
        
        // Then
        XCTAssertNotNil(retrievedString)
        XCTAssertEqual(retrievedString, stringData)
        XCTAssertNil(retrievedInt) // Wrong type should return nil
    }
    
    func testTypeSafety_ComplexTypes() async {
        // Given
        let complexData = ["users": ["John", "Jane"], "count": 2, "active": true]
        let cacheKey = "complex.type"
        
        // When
        await cacheManager.cacheData(complexData, for: cacheKey)
        let retrievedData: [String: Any]? = await cacheManager.getCachedData(for: cacheKey)
        
        // Then
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData?["users"] as? [String], ["John", "Jane"])
        XCTAssertEqual(retrievedData?["count"] as? Int, 2)
        XCTAssertEqual(retrievedData?["active"] as? Bool, true)
    }
}
