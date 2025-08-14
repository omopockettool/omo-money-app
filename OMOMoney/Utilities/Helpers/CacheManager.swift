import Foundation

/// Intelligent caching system for OMOMoney app
/// Provides caching for Core Data operations, validations, and calculations
@MainActor
class CacheManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CacheManager()
    
    // MARK: - Private Properties
    private var dataCache: [String: Any] = [:]
    private var validationCache: [String: Bool] = [:]
    private var calculationCache: [String: Any] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    
    // MARK: - Cache Configuration
    private let dataCacheExpiration: TimeInterval = 300 // 5 minutes
    private let validationCacheExpiration: TimeInterval = 60 // 1 minute
    private let calculationCacheExpiration: TimeInterval = 600 // 10 minutes
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Data Cache Methods
    
    /// Cache Core Data results with expiration
    func cacheData<T>(_ data: T, for key: String) {
        dataCache[key] = data
        cacheTimestamps[key] = Date()
    }
    
    /// Retrieve cached data if not expired
    func getCachedData<T>(for key: String) -> T? {
        guard let timestamp = cacheTimestamps[key],
              let data = dataCache[key] as? T,
              Date().timeIntervalSince(timestamp) < dataCacheExpiration else {
            // Cache expired or not found, remove it
            dataCache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
            return nil
        }
        return data
    }
    
    /// Clear specific data cache
    func clearDataCache(for key: String) {
        dataCache.removeValue(forKey: key)
        cacheTimestamps.removeValue(forKey: key)
    }
    
    /// Clear all data cache
    func clearAllDataCache() {
        dataCache.removeAll()
        cacheTimestamps.removeAll()
    }
    
    // MARK: - Validation Cache Methods
    
    /// Cache validation results
    func cacheValidation(_ isValid: Bool, for key: String) {
        validationCache[key] = isValid
        cacheTimestamps[key] = Date()
    }
    
    /// Get cached validation result
    func getCachedValidation(for key: String) -> Bool? {
        guard let timestamp = cacheTimestamps[key],
              let isValid = validationCache[key],
              Date().timeIntervalSince(timestamp) < validationCacheExpiration else {
            // Cache expired or not found, remove it
            validationCache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
            return nil
        }
        return isValid
    }
    
    /// Clear validation cache for specific key
    func clearValidationCache(for key: String) {
        validationCache.removeValue(forKey: key)
        cacheTimestamps.removeValue(forKey: key)
    }
    
    // MARK: - Calculation Cache Methods
    
    /// Cache calculation results
    func cacheCalculation<T>(_ result: T, for key: String) {
        calculationCache[key] = result
        cacheTimestamps[key] = Date()
    }
    
    /// Get cached calculation result
    func getCachedCalculation<T>(for key: String) -> T? {
        guard let timestamp = cacheTimestamps[key],
              let result = calculationCache[key] as? T,
              Date().timeIntervalSince(timestamp) < calculationCacheExpiration else {
            // Cache expired or not found, remove it
            calculationCache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
            return nil
        }
        return result
    }
    
    /// Clear calculation cache for specific key
    func clearCalculationCache(for key: String) {
        calculationCache.removeValue(forKey: key)
        cacheTimestamps.removeValue(forKey: key)
    }
    
    // MARK: - Cache Management
    
    /// Get cache statistics
    func getCacheStats() -> CacheStats {
        return CacheStats(
            dataCount: dataCache.count,
            validationCount: validationCache.count,
            calculationCount: calculationCache.count
        )
    }
    
    // MARK: - Cache Statistics Structure
    
    struct CacheStats {
        let dataCount: Int
        let validationCount: Int
        let calculationCount: Int
    }
    
    /// Clear all caches
    func clearAllCaches() {
        clearAllDataCache()
        validationCache.removeAll()
        calculationCache.removeAll()
        cacheTimestamps.removeAll()
    }
    
    /// Clean expired cache entries
    func cleanExpiredCache() {
        let now = Date()
        
        // Clean data cache
        let expiredDataKeys = cacheTimestamps.compactMap { key, timestamp in
            now.timeIntervalSince(timestamp) >= dataCacheExpiration ? key : nil
        }
        expiredDataKeys.forEach { clearDataCache(for: $0) }
        
        // Clean validation cache
        let expiredValidationKeys = cacheTimestamps.compactMap { key, timestamp in
            now.timeIntervalSince(timestamp) >= validationCacheExpiration ? key : nil
        }
        expiredValidationKeys.forEach { clearValidationCache(for: $0) }
        
        // Clean calculation cache
        let expiredCalculationKeys = cacheTimestamps.compactMap { key, timestamp in
            now.timeIntervalSince(timestamp) >= calculationCacheExpiration ? key : nil
        }
        expiredCalculationKeys.forEach { clearCalculationCache(for: $0) }
    }
}
