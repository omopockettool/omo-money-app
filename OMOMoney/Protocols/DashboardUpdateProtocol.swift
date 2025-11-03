//
//  DashboardUpdateProtocol.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import Foundation

/// Protocol for dashboard granular updates
protocol DashboardUpdateProtocol: AnyObject {
    
    /// Add new ItemList to dashboard
    func addItemList(_ itemList: ItemList) async
    
    /// Remove ItemList from dashboard  
    func removeItemList(_ itemList: ItemList) async
    
    /// Update existing ItemList in dashboard
    func updateItemList(_ itemList: ItemList) async
    
    /// Refresh dashboard data (fallback for complex operations)
    func refreshAfterItemListCreation() async
}