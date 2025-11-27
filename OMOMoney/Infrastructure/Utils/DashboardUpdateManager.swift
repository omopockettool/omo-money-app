//
//  DashboardUpdateManager.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import Foundation
import Combine

/// Manager for coordinating dashboard updates across different contexts
@MainActor
class DashboardUpdateManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = DashboardUpdateManager()
    
    // MARK: - Published Properties
    @Published private(set) var isUpdating = false
    
    // MARK: - Private Properties
    private var updateQueue: [DashboardUpdate] = []
    private var isProcessingQueue = false
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Schedule a dashboard update
    func scheduleUpdate(_ update: DashboardUpdate) {
        print("📝 DashboardUpdateManager: Scheduling update: \(update.type)")
        
        updateQueue.append(update)
        
        if !isProcessingQueue {
            processUpdateQueue()
        }
    }
    
    /// Process pending updates
    private func processUpdateQueue() {
        guard !updateQueue.isEmpty, !isProcessingQueue else { return }
        
        Task {
            isProcessingQueue = true
            isUpdating = true
            
            print("🔄 DashboardUpdateManager: Processing \(updateQueue.count) updates...")
            
            // Process updates in batch for better performance
            let currentUpdates = updateQueue
            updateQueue.removeAll()
            
            // Group updates by type for optimization
            let groupedUpdates = Dictionary(grouping: currentUpdates) { $0.type }
            
            // Process each type of update
            for (updateType, updates) in groupedUpdates {
                await processUpdatesOfType(updateType, updates: updates)
            }
            
            isProcessingQueue = false
            isUpdating = false
            
            print("✅ DashboardUpdateManager: Finished processing updates")
            
            // Process any new updates that came in while processing
            if !updateQueue.isEmpty {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                processUpdateQueue()
            }
        }
    }
    
    /// Process updates of a specific type
    private func processUpdatesOfType(_ type: DashboardUpdateType, updates: [DashboardUpdate]) async {
        guard let dashboard = updates.first?.dashboard else { return }
        
        switch type {
        case .add:
            for update in updates {
                if let itemList = update.itemList {
                    await dashboard.addItemList(itemList)
                }
            }
            
        case .remove:
            for update in updates {
                if let itemList = update.itemList {
                    await dashboard.removeItemList(itemList)
                }
            }
            
        case .update:
            for update in updates {
                if let itemList = update.itemList {
                    await dashboard.updateItemList(itemList)
                }
            }
            
        case .refresh:
            // Only do one refresh even if multiple refresh requests came in
            Task {
                await dashboard.refreshAfterItemListCreation()
            }
        }
    }
}

// MARK: - Supporting Types

struct DashboardUpdate {
    let type: DashboardUpdateType
    let itemList: ItemList?
    weak var dashboard: DashboardUpdateProtocol?
    let timestamp: Date
    
    init(type: DashboardUpdateType, itemList: ItemList? = nil, dashboard: DashboardUpdateProtocol?) {
        self.type = type
        self.itemList = itemList
        self.dashboard = dashboard
        self.timestamp = Date()
    }
}

enum DashboardUpdateType: String, CaseIterable {
    case add = "add"
    case remove = "remove"
    case update = "update"
    case refresh = "refresh"
}