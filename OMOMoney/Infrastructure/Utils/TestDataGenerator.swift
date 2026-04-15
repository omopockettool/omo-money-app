//
//  TestDataGenerator.swift
//  OMOMoney
//

import Foundation
import SwiftData

@MainActor
final class TestDataGenerator {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Generate

    func generateMassiveTestData(itemListCount: Int = 500, itemsPerList: Int = 3) async throws {
        print("🔄 TestDataGenerator: Starting generation of \(itemListCount) ItemLists...")

        guard let group = try fetchFirstGroup() else {
            throw TestDataError.missingRequiredData
        }

        let categories    = try fetchCategories(for: group)
        let paymentMethods = try fetchPaymentMethods(for: group)

        guard !categories.isEmpty, !paymentMethods.isEmpty else {
            throw TestDataError.missingRequiredData
        }

        print("✅ TestDataGenerator: Using group '\(group.name)' — \(categories.count) categories, \(paymentMethods.count) payment methods")

        let batchSize   = 50
        let totalBatches = (itemListCount + batchSize - 1) / batchSize

        for batchIndex in 0..<totalBatches {
            let start = batchIndex * batchSize
            let end   = min(start + batchSize, itemListCount)
            print("🔄 TestDataGenerator: Batch \(batchIndex + 1)/\(totalBatches)")

            for i in start..<end {
                let itemList = SDItemList(
                    itemListDescription: generateRandomDescription(index: i),
                    date: generateRandomDate()
                )
                itemList.group          = group
                itemList.category       = categories.randomElement()
                itemList.paymentMethod  = paymentMethods.randomElement()

                context.insert(itemList)

                for j in 1...itemsPerList {
                    let item = SDItem(
                        itemDescription: "Item \(j) for \(itemList.itemListDescription)",
                        amount: Double.random(in: 1.0...100.0),
                        quantity: Int.random(in: 1...5)
                    )
                    item.itemList = itemList
                    context.insert(item)
                }
            }

            try context.save()
            print("✅ TestDataGenerator: Batch \(batchIndex + 1) saved")
        }

        print("🎉 TestDataGenerator: Generated \(itemListCount) ItemLists with \(itemListCount * itemsPerList) items!")
    }

    // MARK: - Clean

    func cleanAllTestData() async throws {
        print("🧹 TestDataGenerator: Cleaning all test data...")

        let items     = try context.fetch(FetchDescriptor<SDItem>())
        let itemLists = try context.fetch(FetchDescriptor<SDItemList>())

        items.forEach     { context.delete($0) }
        itemLists.forEach { context.delete($0) }

        try context.save()
        print("✅ TestDataGenerator: All test data cleaned")
    }

    // MARK: - Private helpers

    private func fetchFirstGroup() throws -> SDGroup? {
        var descriptor = FetchDescriptor<SDGroup>()
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func fetchCategories(for group: SDGroup) throws -> [SDCategory] {
        let targetId = group.id
        let descriptor = FetchDescriptor<SDCategory>(
            predicate: #Predicate { $0.group?.id == targetId }
        )
        return try context.fetch(descriptor)
    }

    private func fetchPaymentMethods(for group: SDGroup) throws -> [SDPaymentMethod] {
        let targetId = group.id
        let descriptor = FetchDescriptor<SDPaymentMethod>(
            predicate: #Predicate { $0.group?.id == targetId && $0.isActive }
        )
        return try context.fetch(descriptor)
    }

    private func generateRandomDescription(index: Int) -> String {
        let prefixes = ["Compra", "Gasto", "Pago", "Factura", "Recibo", "Ticket"]
        let suffixes = ["supermercado", "gasolina", "restaurante", "farmacia", "ropa", "hogar", "ocio"]
        return "\(prefixes.randomElement()!) \(suffixes.randomElement()!) #\(index + 1)"
    }

    private func generateRandomDate() -> Date {
        let calendar = Calendar.current
        let now      = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: now)
        else { return now }
        let randomDay = Int.random(in: 0..<range.count)
        return calendar.date(byAdding: .day, value: randomDay, to: firstDay) ?? now
    }
}

// MARK: - Error

enum TestDataError: LocalizedError {
    case missingRequiredData

    var errorDescription: String? {
        "Missing required group, categories, or payment methods"
    }
}
