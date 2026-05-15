import XCTest
@testable import OMOMoney

@MainActor
final class CacheManagerTests: XCTestCase {

    var cacheManager: CacheManager!

    override func setUp() async throws {
        cacheManager = CacheManager.shared
        cacheManager.clearAllCaches()
    }

    override func tearDown() async throws {
        cacheManager.clearAllCaches()
        cacheManager = nil
    }

    // MARK: - Data Cache

    func testDataCache_StoreAndRetrieve() async {
        cacheManager.cacheData("value", for: "key")
        let result: String? = cacheManager.getCachedData(for: "key")
        XCTAssertEqual(result, "value")
    }

    func testDataCache_ClearSpecific() async {
        cacheManager.cacheData("data1", for: "key1")
        cacheManager.cacheData("data2", for: "key2")
        cacheManager.clearDataCache(for: "key1")

        let result1: String? = cacheManager.getCachedData(for: "key1")
        let result2: String? = cacheManager.getCachedData(for: "key2")

        XCTAssertNil(result1)
        XCTAssertEqual(result2, "data2")
    }

    func testDataCache_ClearAll() async {
        cacheManager.cacheData("data1", for: "key1")
        cacheManager.cacheData("data2", for: "key2")
        cacheManager.clearAllDataCache()

        let result1: String? = cacheManager.getCachedData(for: "key1")
        let result2: String? = cacheManager.getCachedData(for: "key2")

        XCTAssertNil(result1)
        XCTAssertNil(result2)
    }

    // MARK: - Validation Cache

    func testValidationCache_StoreAndRetrieve() async {
        cacheManager.cacheValidation(true, for: "key")
        let result = cacheManager.getCachedValidation(for: "key")
        XCTAssertEqual(result, true)
    }

    func testValidationCache_ClearSpecific() async {
        cacheManager.cacheValidation(true, for: "key1")
        cacheManager.cacheValidation(false, for: "key2")
        cacheManager.clearValidationCache(for: "key1")

        XCTAssertNil(cacheManager.getCachedValidation(for: "key1"))
        XCTAssertEqual(cacheManager.getCachedValidation(for: "key2"), false)
    }

    // MARK: - Calculation Cache

    func testCalculationCache_StoreAndRetrieve() async {
        cacheManager.cacheCalculation(3.14, for: "key")
        let result: Double? = cacheManager.getCachedCalculation(for: "key")
        XCTAssertEqual(result, 3.14)
    }

    func testCalculationCache_ClearSpecific() async {
        cacheManager.cacheCalculation(10.0, for: "key1")
        cacheManager.cacheCalculation(20.0, for: "key2")
        cacheManager.clearCalculationCache(for: "key1")

        let result1: Double? = cacheManager.getCachedCalculation(for: "key1")
        let result2: Double? = cacheManager.getCachedCalculation(for: "key2")

        XCTAssertNil(result1)
        XCTAssertEqual(result2, 20.0)
    }

    // MARK: - Stats

    func testCacheStats_Empty() async {
        let stats = cacheManager.getCacheStats()
        XCTAssertEqual(stats.dataCount, 0)
        XCTAssertEqual(stats.validationCount, 0)
        XCTAssertEqual(stats.calculationCount, 0)
    }

    func testCacheStats_WithData() async {
        cacheManager.cacheData("data", for: "d")
        cacheManager.cacheValidation(true, for: "v")
        cacheManager.cacheCalculation(42.0, for: "c")

        let stats = cacheManager.getCacheStats()
        XCTAssertEqual(stats.dataCount, 1)
        XCTAssertEqual(stats.validationCount, 1)
        XCTAssertEqual(stats.calculationCount, 1)
    }

    func testClearAllCaches() async {
        cacheManager.cacheData("data", for: "d")
        cacheManager.cacheValidation(true, for: "v")
        cacheManager.cacheCalculation(42.0, for: "c")
        cacheManager.clearAllCaches()

        let stats = cacheManager.getCacheStats()
        XCTAssertEqual(stats.dataCount, 0)
        XCTAssertEqual(stats.validationCount, 0)
        XCTAssertEqual(stats.calculationCount, 0)
    }

    // MARK: - Type Safety

    func testTypeSafety_WrongTypeReturnsNil() async {
        cacheManager.cacheData("string", for: "key")
        let result: Int? = cacheManager.getCachedData(for: "key")
        XCTAssertNil(result)
    }

    func testCleanExpiredCache_DoesNotRemoveFreshEntries() async {
        cacheManager.cacheData("data", for: "d")
        cacheManager.cacheValidation(true, for: "v")
        cacheManager.cacheCalculation(42.0, for: "c")
        cacheManager.cleanExpiredCache()

        let stats = cacheManager.getCacheStats()
        XCTAssertEqual(stats.dataCount, 1)
        XCTAssertEqual(stats.validationCount, 1)
        XCTAssertEqual(stats.calculationCount, 1)
    }
}
