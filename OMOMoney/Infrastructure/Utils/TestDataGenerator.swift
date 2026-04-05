//
//  TestDataGenerator.swift
//  OMOMoney
//
//  Created by Assistant on 5 Nov 2025.
//

import Foundation
import CoreData

class TestDataGenerator {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// Generate massive test data for performance testing
    func generateMassiveTestData(itemListCount: Int = 500, itemsPerList: Int = 3, targetGroup: Group? = nil) async throws {
        print("🔄 TestDataGenerator: Starting generation of \(itemListCount) ItemLists with \(itemsPerList) items each...")

        // Get existing group and user
        let group: Group
        if let targetGroup = targetGroup {
            print("🎯 TestDataGenerator: Using provided target group - ID: \(targetGroup.id?.uuidString ?? "nil"), Name: '\(targetGroup.name ?? "No Name")'")
            group = targetGroup
        } else {
            guard let fetchedGroup = try await getOrCreateTestGroup() else {
                throw TestDataError.missingRequiredData
            }
            print("🔍 TestDataGenerator: Using first available group - ID: \(fetchedGroup.id?.uuidString ?? "nil"), Name: '\(fetchedGroup.name ?? "No Name")'")
            group = fetchedGroup
        }

        guard (try await getOrCreateTestUser()) != nil else {
            throw TestDataError.missingRequiredData
        }

        let categories = try await getTestCategories(for: group)
        let paymentMethods = try await getTestPaymentMethods(for: group)
        
        guard !categories.isEmpty, !paymentMethods.isEmpty else {
            throw TestDataError.missingRequiredData
        }
        
        print("✅ TestDataGenerator: Found group '\(group.name ?? "N/A")' with \(categories.count) categories and \(paymentMethods.count) payment methods")
        
        // Generate ItemLists in batches to avoid memory issues
        let batchSize = 50
        let totalBatches = (itemListCount + batchSize - 1) / batchSize
        
        for batchIndex in 0..<totalBatches {
            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, itemListCount)
            let currentBatchSize = endIndex - startIndex
            
            print("🔄 TestDataGenerator: Batch \(batchIndex + 1)/\(totalBatches) - Creating \(currentBatchSize) ItemLists...")
            
            try await context.perform {
                for i in startIndex..<endIndex {
                    let itemList = ItemList(context: self.context)
                    itemList.id = UUID()
                    itemList.itemListDescription = self.generateRandomDescription(index: i)
                    itemList.date = self.generateRandomDate()
                    itemList.createdAt = Date()

                    // ✅ FIX: Set both relationship AND attribute for group
                    itemList.group = group
                    itemList.groupId = group.id

                    // ✅ FIX: Set both relationship AND attribute for category
                    if let category = categories.randomElement() {
                        itemList.category = category
                        itemList.categoryId = category.id
                    }

                    // ✅ FIX: Set both relationship AND attribute for payment method
                    if let paymentMethod = paymentMethods.randomElement() {
                        itemList.paymentMethod = paymentMethod
                        itemList.paymentMethodId = paymentMethod.id
                    }

                    // Create items for this ItemList
                    for j in 1...itemsPerList {
                        let item = Item(context: self.context)
                        item.id = UUID()
                        item.itemDescription = "Item \(j) for \(itemList.itemListDescription ?? "Unknown")"
                        item.amount = NSDecimalNumber(decimal: Decimal(Double.random(in: 1.0...100.0)))
                        item.quantity = Int32.random(in: 1...5)
                        item.createdAt = Date()
                        item.itemList = itemList
                    }
                }

                try self.context.save()
            }
            
            print("✅ TestDataGenerator: Batch \(batchIndex + 1) completed")
        }

        // ✅ CRITICAL FIX: Invalidate ItemListService cache after generating test data
        if let groupId = group.id {
            let cacheKey = "ItemListService.groupItemLists.\(groupId.uuidString)"
            let timestampKey = "\(cacheKey).timestamp"
            await CacheManager.shared.clearDataCache(for: cacheKey)
            await CacheManager.shared.clearDataCache(for: timestampKey)
            print("🗑️ TestDataGenerator: Cache invalidated for group after test data generation")
        }

        print("🎉 TestDataGenerator: Successfully generated \(itemListCount) ItemLists with \(itemListCount * itemsPerList) items!")
    }
    
    /// Clean all test data
    func cleanAllTestData() async throws {
        print("🧹 TestDataGenerator: Cleaning all test data...")
        
        try await context.perform {
            // Delete all Items
            let itemRequest: NSFetchRequest<NSFetchRequestResult> = Item.fetchRequest()
            let itemDeleteRequest = NSBatchDeleteRequest(fetchRequest: itemRequest)
            try self.context.execute(itemDeleteRequest)
            
            // Delete all ItemLists
            let itemListRequest: NSFetchRequest<NSFetchRequestResult> = ItemList.fetchRequest()
            let itemListDeleteRequest = NSBatchDeleteRequest(fetchRequest: itemListRequest)
            try self.context.execute(itemListDeleteRequest)
            
            try self.context.save()
        }
        
        print("✅ TestDataGenerator: All test data cleaned")
    }
    
    // MARK: - Private Helpers
    
    private func getOrCreateTestGroup() async throws -> Group? {
        let request: NSFetchRequest<Group> = Group.fetchRequest()
        request.fetchLimit = 1
        
        let groups = try await context.perform {
            try self.context.fetch(request)
        }
        
        return groups.first
    }
    
    private func getOrCreateTestUser() async throws -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        
        let users = try await context.perform {
            try self.context.fetch(request)
        }
        
        return users.first
    }
    
    private func getTestCategories(for group: Group) async throws -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        // ✅ Query by UUID instead of relationship
        if let groupId = group.id {
            request.predicate = NSPredicate(format: "group.id == %@", groupId as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "group == %@", group)
        }

        return try await context.perform {
            try self.context.fetch(request)
        }
    }

    private func getTestPaymentMethods(for group: Group) async throws -> [PaymentMethod] {
        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        // ✅ Query by UUID instead of relationship
        if let groupId = group.id {
            request.predicate = NSPredicate(format: "group.id == %@ AND isActive == YES", groupId as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "group == %@ AND isActive == YES", group)
        }

        return try await context.perform {
            try self.context.fetch(request)
        }
    }
    
    private func generateRandomDescription(index: Int) -> String {
        let prefixes = ["Compra", "Gasto", "Pago", "Factura", "Recibo", "Ticket", "Consumo", "Adquisición"]
        let suffixes = ["supermercado", "gasolina", "restaurante", "farmacia", "ropa", "electrónicos", "hogar", "ocio", "transporte", "salud", "educación", "servicios"]
        
        let prefix = prefixes.randomElement() ?? "Gasto"
        let suffix = suffixes.randomElement() ?? "general"
        
        return "\(prefix) \(suffix) #\(index + 1)"
    }
    
    private func generateRandomDate() -> Date {
        let calendar = Calendar.current
        let now = Date()

        // ✅ Generate dates within CURRENT MONTH to be visible in dashboard
        // Get first day of current month
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let firstDayOfMonth = calendar.date(from: components) else { return now }

        // Get number of days in current month
        guard let range = calendar.range(of: .day, in: .month, for: now) else { return now }
        let daysInMonth = range.count

        // Generate random day within current month
        let randomDay = Int.random(in: 0..<daysInMonth)
        return calendar.date(byAdding: .day, value: randomDay, to: firstDayOfMonth) ?? now
    }

    /// Delete old test data for a group
    private func deleteOldTestData(for group: Group) async throws {
        guard let groupId = group.id else { return }

        print("🗑️ TestDataGenerator: Deleting old ItemLists for group '\(group.name ?? "N/A")'...")

        let deletedCount = try await context.perform {
            let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
            request.predicate = NSPredicate(format: "group.id == %@", groupId as CVarArg)

            let itemLists = try self.context.fetch(request)
            let count = itemLists.count

            for itemList in itemLists {
                self.context.delete(itemList)
            }

            try self.context.save()
            return count
        }

        print("✅ TestDataGenerator: Deleted \(deletedCount) old ItemLists")
    }
}

enum TestDataError: Error {
    case missingRequiredData
    
    var localizedDescription: String {
        switch self {
        case .missingRequiredData:
            return "Missing required group, user, categories, or payment methods"
        }
    }
}