import Foundation
import CoreData

/// Performance monitoring utility for OMOMoney app
/// Tracks app performance metrics and provides insights
@MainActor
class PerformanceMonitor: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PerformanceMonitor()
    
    // MARK: - Published Properties
    @Published var metrics: PerformanceMetrics = PerformanceMetrics()
    
    // MARK: - Private Properties
    private var operationStartTimes: [String: Date] = [:]
    private var operationDurations: [String: [TimeInterval]] = [:]
    
    // MARK: - Initialization
    private init() {
        startMonitoring()
    }
    
    // MARK: - Performance Tracking
    
    /// Start tracking an operation
    func startOperation(_ operationName: String) {
        operationStartTimes[operationName] = Date()
    }
    
    /// End tracking an operation and record duration
    func endOperation(_ operationName: String) {
        guard let startTime = operationStartTimes[operationName] else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        
        if operationDurations[operationName] == nil {
            operationDurations[operationName] = []
        }
        operationDurations[operationName]?.append(duration)
        
        // Keep only last 100 measurements per operation
        if let count = operationDurations[operationName]?.count, count > 100 {
            operationDurations[operationName]?.removeFirst()
        }
        
        operationStartTimes.removeValue(forKey: operationName)
        updateMetrics()
    }
    
    /// Track Core Data operation
    func trackCoreDataOperation<T>(_ operationName: String, operation: () async throws -> T) async throws -> T {
        startOperation("CoreData_\(operationName)")
        defer { endOperation("CoreData_\(operationName)") }
        return try await operation()
    }
    
    /// Track UI operation
    func trackUIOperation<T>(_ operationName: String, operation: () -> T) -> T {
        startOperation("UI_\(operationName)")
        defer { endOperation("UI_\(operationName)") }
        return operation()
    }
    
    // MARK: - Metrics Calculation
    
    private func updateMetrics() {
        var newMetrics = PerformanceMetrics()
        
        // Calculate average durations
        for (operation, durations) in operationDurations {
            if !durations.isEmpty {
                let average = durations.reduce(0, +) / Double(durations.count)
                let max = durations.max() ?? 0
                let min = durations.min() ?? 0
                
                newMetrics.operationMetrics[operation] = OperationMetric(
                    averageDuration: average,
                    maxDuration: max,
                    minDuration: min,
                    sampleCount: durations.count
                )
            }
        }
        
        // Calculate cache hit ratio
        newMetrics.cacheHitRatio = CacheManager.shared.getCacheHitRatio()
        
        // Update metrics
        metrics = newMetrics
    }
    
    // MARK: - Performance Analysis
    
    /// Get slow operations (> 100ms average)
    func getSlowOperations() -> [String: OperationMetric] {
        return metrics.operationMetrics.filter { $0.value.averageDuration > 0.1 }
    }
    
    /// Get performance summary
    func getPerformanceSummary() -> PerformanceSummary {
        let slowOperations = getSlowOperations()
        let totalOperations = metrics.operationMetrics.count
        
        return PerformanceSummary(
            totalOperationsTracked: totalOperations,
            slowOperationsCount: slowOperations.count,
            averageCacheHitRatio: metrics.cacheHitRatio,
            performanceScore: calculatePerformanceScore()
        )
    }
    
    private func calculatePerformanceScore() -> Double {
        let cacheScore = metrics.cacheHitRatio * 40 // 40% weight
        let slowOpsPenalty = Double(getSlowOperations().count) * 10 // -10 points per slow operation
        let baseScore = 60.0 // Base score
        
        return max(0, min(100, baseScore + cacheScore - slowOpsPenalty))
    }
    
    // MARK: - Monitoring Control
    
    private func startMonitoring() {
        // Start automatic cache cleanup
        CacheManager.shared.startAutomaticCacheCleanup()
        
        // Schedule periodic metrics update
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetrics()
            }
        }
    }
    
    /// Reset all performance tracking
    func resetMetrics() {
        operationStartTimes.removeAll()
        operationDurations.removeAll()
        metrics = PerformanceMetrics()
    }
    
    /// Export performance data for analysis
    func exportPerformanceData() -> [String: Any] {
        return [
            "metrics": metrics.operationMetrics.mapValues { metric in
                [
                    "averageDuration": metric.averageDuration,
                    "maxDuration": metric.maxDuration,
                    "minDuration": metric.minDuration,
                    "sampleCount": metric.sampleCount
                ]
            },
            "cacheHitRatio": metrics.cacheHitRatio,
            "summary": getPerformanceSummary().dictionaryRepresentation()
        ]
    }
}

// MARK: - Performance Data Structures

struct PerformanceMetrics {
    var operationMetrics: [String: OperationMetric] = [:]
    var cacheHitRatio: Double = 0.0
}

struct OperationMetric {
    let averageDuration: TimeInterval
    let maxDuration: TimeInterval
    let minDuration: TimeInterval
    let sampleCount: Int
}

struct PerformanceSummary {
    let totalOperationsTracked: Int
    let slowOperationsCount: Int
    let averageCacheHitRatio: Double
    let performanceScore: Double
    
    func dictionaryRepresentation() -> [String: Any] {
        return [
            "totalOperationsTracked": totalOperationsTracked,
            "slowOperationsCount": slowOperationsCount,
            "averageCacheHitRatio": averageCacheHitRatio,
            "performanceScore": performanceScore
        ]
    }
}
