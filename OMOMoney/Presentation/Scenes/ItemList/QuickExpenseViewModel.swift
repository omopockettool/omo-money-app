import Foundation
import CoreData

@MainActor
final class QuickExpenseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var categories: [Category] = []
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var description = ""
    @Published var price = ""  // Optional price field - empty means no automatic item
    @Published var date = Date()
    @Published var selectedCategory: Category?
    @Published var selectedPaymentMethod: PaymentMethod?
    @Published var expenseCreatedSuccessfully = false
    
    // MARK: - Dependencies
    private let itemListService: any ItemListServiceProtocol
    private let categoryService: any CategoryServiceProtocol
    private let itemService: any ItemServiceProtocol
    private let paymentMethodService: any PaymentMethodServiceProtocol
    
    // MARK: - Initialization
    
    init(
        itemListService: any ItemListServiceProtocol,
        categoryService: any CategoryServiceProtocol,
        itemService: any ItemServiceProtocol,
        paymentMethodService: any PaymentMethodServiceProtocol
    ) {
        self.itemListService = itemListService
        self.categoryService = categoryService
        self.itemService = itemService
        self.paymentMethodService = paymentMethodService
        
        print("🔄 QuickExpenseViewModel: Initialized for quick expense creation")
    }
    
    // MARK: - Computed Properties
    
    /// Check if the form can be saved
    var canSave: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedCategory != nil &&
        selectedPaymentMethod != nil
    }
    
    /// Check if price is valid (empty or valid decimal)
    var isPriceValid: Bool {
        if price.isEmpty { return true }
        return NSDecimalNumber(string: price) != NSDecimalNumber.notANumber
    }
    
    /// Get price as NSDecimalNumber, returns nil if empty or invalid
    var priceAsDecimal: NSDecimalNumber? {
        guard !price.isEmpty else { return nil }
        let decimal = NSDecimalNumber(string: price)
        return decimal == NSDecimalNumber.notANumber ? nil : decimal
    }
    
    // MARK: - Public Methods
    
    /// Load categories for the specified group using cache
    func loadCategories(for group: Group) async {
        let cacheKey = "categories_\(group.id?.uuidString ?? "unknown")"
        
        print("🔍 QuickExpenseViewModel: Loading categories for group '\(group.name ?? "Unknown")'")
        print("🔍 QuickExpenseViewModel: Cache key: \(cacheKey)")
        
        // Try to get from cache first
        if let cachedCategories: [Category] = CacheManager.shared.getCachedData(for: cacheKey) {
            categories = cachedCategories
            print("🟢 QuickExpenseViewModel: ✅ Categories loaded from CACHE (\(categories.count) items)")
            return
        }
        
        print("🔄 QuickExpenseViewModel: Cache miss - loading from DATABASE...")
        
        // If not in cache, load from database
        isLoading = true
        errorMessage = nil
        
        do {
            categories = try await categoryService.getCategories(for: group)
            
            // Cache the result
            CacheManager.shared.cacheData(categories, for: cacheKey)
            print("🟡 QuickExpenseViewModel: ✅ Categories loaded from SERVICE and cached (\(categories.count) items)")
        } catch {
            errorMessage = "Error al cargar categorías: \(error.localizedDescription)"
            print("❌ QuickExpenseViewModel: Error loading categories: \(error)")
        }
        
        isLoading = false
    }
    
    /// Load active payment methods for the specified group using cache
    func loadPaymentMethods(for group: Group) async {
        let cacheKey = "payment_methods_\(group.id?.uuidString ?? "unknown")"
        
        print("🔍 QuickExpenseViewModel: Loading payment methods for group '\(group.name ?? "Unknown")'")
        print("🔍 QuickExpenseViewModel: Cache key: \(cacheKey)")
        
        // Try to get from cache first
        if let cachedPaymentMethods: [PaymentMethod] = CacheManager.shared.getCachedData(for: cacheKey) {
            paymentMethods = cachedPaymentMethods
            print("🟢 QuickExpenseViewModel: ✅ Payment methods loaded from CACHE (\(paymentMethods.count) items)")
            return
        }
        
        print("🔄 QuickExpenseViewModel: Cache miss - loading from DATABASE...")
        
        // If not in cache, load from database
        isLoading = true
        errorMessage = nil
        
        do {
            paymentMethods = try await paymentMethodService.getActivePaymentMethods(for: group)
            
            // Cache the result
            CacheManager.shared.cacheData(paymentMethods, for: cacheKey)
            print("🟡 QuickExpenseViewModel: ✅ Payment methods loaded from SERVICE and cached (\(paymentMethods.count) items)")
        } catch {
            errorMessage = "Error al cargar métodos de pago: \(error.localizedDescription)"
            print("❌ QuickExpenseViewModel: Error loading payment methods: \(error)")
        }
        
        isLoading = false
    }
    
    /// Create quick expense - ItemList + optional automatic Item
    /// Returns the created ItemList if successful, nil otherwise
    func createQuickExpense(
        group: Group
    ) async -> ItemList? {
        guard canSave && isPriceValid else {
            errorMessage = "Formulario incompleto o precio inválido"
            return nil
        }
        
        guard let category = selectedCategory,
              let paymentMethod = selectedPaymentMethod else {
            errorMessage = "Selecciona categoría y método de pago"
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        expenseCreatedSuccessfully = false
        
        do {
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("🔄 QuickExpenseViewModel: Creating quick expense...")
            print("📝 Description: \(trimmedDescription)")
            print("💰 Price: \(price.isEmpty ? "None (ItemList only)" : price)")
            print("📂 Category: \(category.name ?? "Unknown")")
            print("💳 Payment Method: \(paymentMethod.name ?? "Unknown")")
            
            // Step 1: Create ItemList
            let itemList = try await itemListService.createItemList(
                description: trimmedDescription,
                date: date,
                categoryId: category.id ?? UUID(),
                groupId: group.id ?? UUID(),
                paymentMethodId: paymentMethod.id
            )
            
            print("✅ QuickExpenseViewModel: ItemList created successfully")
            
            // Step 2: If price provided, create automatic Item
            if let priceDecimal = priceAsDecimal {
                print("🔄 QuickExpenseViewModel: Creating automatic Item with price: \(priceDecimal)")
                
                let _ = try await itemService.createItem(
                    description: trimmedDescription,  // Same description as ItemList
                    amount: priceDecimal,
                    quantity: 1,
                    itemList: itemList
                )
                
                print("✅ QuickExpenseViewModel: Automatic Item created successfully")
            } else {
                print("ℹ️ QuickExpenseViewModel: No price provided, ItemList created without Items")
            }
            
            print("✅ QuickExpenseViewModel: Quick expense creation completed")
            print("💡 QuickExpenseViewModel: Returning ItemList for incremental cache update")
            
            // Clear cache to ensure fresh data on next load (in case categories/payment methods were modified elsewhere)
            clearCacheForGroup(group)
            
            expenseCreatedSuccessfully = true
            isLoading = false
            return itemList
            
        } catch {
            errorMessage = "Error al crear gasto: \(error.localizedDescription)"
            print("❌ QuickExpenseViewModel: Error creating quick expense: \(error)")
            isLoading = false
            return nil
        }
    }
    
    /// Reset form to initial state
    func resetForm() {
        description = ""
        price = ""
        date = Date()
        selectedCategory = nil
        selectedPaymentMethod = nil
        errorMessage = nil
        expenseCreatedSuccessfully = false
        print("🔄 QuickExpenseViewModel: Form reset")
    }
    
    /// Load initial data for a specific group
    func loadInitialData(for group: Group) async {
        await loadCategories(for: group)
        await loadPaymentMethods(for: group)
    }
    
    /// Clear cache for a specific group (useful when data changes)
    func clearCacheForGroup(_ group: Group) {
        let categoryCacheKey = "categories_\(group.id?.uuidString ?? "unknown")"
        let paymentMethodCacheKey = "payment_methods_\(group.id?.uuidString ?? "unknown")"
        
        print("🧹 QuickExpenseViewModel: Clearing cache for group '\(group.name ?? "Unknown")'")
        print("🧹 QuickExpenseViewModel: Clearing cache keys:")
        print("   - Categories: \(categoryCacheKey)")
        print("   - Payment Methods: \(paymentMethodCacheKey)")
        
        CacheManager.shared.clearDataCache(for: categoryCacheKey)
        CacheManager.shared.clearDataCache(for: paymentMethodCacheKey)
        print("✅ QuickExpenseViewModel: Cache cleared successfully for group")
    }
    
    /// Refresh data by clearing cache and reloading
    func refreshData(for group: Group) async {
        clearCacheForGroup(group)
        await loadInitialData(for: group)
    }
}