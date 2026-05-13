
import Foundation
import UIKit
import Observation

@MainActor

@Observable
final class AddItemListViewModel {
    private struct UsageMemorySnapshot {
        let itemListDescription: String
        let createdAt: Date
        let categoryId: UUID?
        let paymentMethodId: UUID?
    }

    // MARK: - Published Properties
    var categories: [SDCategory] = []
    var paymentMethods: [SDPaymentMethod] = []
    var availableGroups: [SDGroup] = []
    var selectedGroup: SDGroup?
    var isLoading = false
    var errorMessage: String?
    var toast: ToastMessage?
    var description = ""
    var price = ""
    var date = Date()
    var selectedCategory: SDCategory?
    var selectedPaymentMethod: SDPaymentMethod?
    var suggestions: [ConceptSuggestion] = []
    var lastUsedConcept: String?
    @ObservationIgnored var lastUsedCategoryIds: [UUID] = []
    @ObservationIgnored var lastUsedPaymentMethodId: UUID?

    // MARK: - Dependencies
    private let createItemListUseCase: CreateItemListUseCase
    private let createItemUseCase: CreateItemUseCase
    private let updateItemListUseCase: UpdateItemListUseCase
    private let fetchItemListsUseCase: FetchItemListsUseCase
    private let fetchCategoriesUseCase: FetchCategoriesUseCase
    private let fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let fetchGroupsForUserUseCase: FetchGroupsForUserUseCase
    private let itemListToEdit: SDItemList?
    private let preferredCategoryId: UUID?
    @ObservationIgnored private let cacheManager = CacheManager.shared
    @ObservationIgnored private let categoryUsageLimit = 3
    @ObservationIgnored private var usageMemorySnapshots: [UsageMemorySnapshot] = []
    @ObservationIgnored private var didManuallyChoosePaymentMethod = false
    @ObservationIgnored private var hasLoadedFormData = false

    // MARK: - Computed

    var isEditMode: Bool { itemListToEdit != nil }

    // MARK: - Initialization

    init(
        itemListToEdit: SDItemList? = nil,
        createItemListUseCase: CreateItemListUseCase,
        createItemUseCase: CreateItemUseCase,
        updateItemListUseCase: UpdateItemListUseCase,
        fetchItemListsUseCase: FetchItemListsUseCase,
        fetchCategoriesUseCase: FetchCategoriesUseCase,
        fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase,
        getCurrentUserUseCase: GetCurrentUserUseCase,
        fetchGroupsForUserUseCase: FetchGroupsForUserUseCase,
        preferredCategoryId: UUID? = nil
    ) {
        self.itemListToEdit = itemListToEdit
        self.preferredCategoryId = preferredCategoryId
        self.createItemListUseCase = createItemListUseCase
        self.createItemUseCase = createItemUseCase
        self.updateItemListUseCase = updateItemListUseCase
        self.fetchItemListsUseCase = fetchItemListsUseCase
        self.fetchCategoriesUseCase = fetchCategoriesUseCase
        self.fetchPaymentMethodsUseCase = fetchPaymentMethodsUseCase
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.fetchGroupsForUserUseCase = fetchGroupsForUserUseCase

        if let toEdit = itemListToEdit {
            self.description = toEdit.itemListDescription
            self.date = toEdit.date
            self.selectedGroup = toEdit.group
        }
    }

    convenience init(
        itemListToEdit: SDItemList? = nil,
        initialDate: Date? = nil,
        preferredCategoryId: UUID? = nil
    ) {
        let appContainer = AppDIContainer.shared
        self.init(
            itemListToEdit: itemListToEdit,
            createItemListUseCase: appContainer.makeCreateItemListUseCase(),
            createItemUseCase: appContainer.makeCreateItemUseCase(),
            updateItemListUseCase: appContainer.makeUpdateItemListUseCase(),
            fetchItemListsUseCase: appContainer.makeFetchItemListsUseCase(),
            fetchCategoriesUseCase: appContainer.makeFetchCategoriesUseCase(),
            fetchPaymentMethodsUseCase: appContainer.makeFetchPaymentMethodsUseCase(),
            getCurrentUserUseCase: appContainer.makeGetCurrentUserUseCase(),
            fetchGroupsForUserUseCase: appContainer.makeFetchGroupsForUserUseCase(),
            preferredCategoryId: preferredCategoryId
        )
        if itemListToEdit == nil, let initialDate {
            self.date = initialDate
        }
    }

    // MARK: - Computed Properties

    var formattedDate: String { DateFormatterHelper.formatDate(date) }

    var canSave: Bool {
        isPriceValid
    }

    var isPriceValid: Bool {
        if price.isEmpty { return true }
        let normalizedPrice = price.replacingOccurrences(of: ",", with: ".")
        if normalizedPrice.hasSuffix(".") { return true }
        return NSDecimalNumber(string: normalizedPrice) != NSDecimalNumber.notANumber
    }

    var priceAsDecimal: Decimal? {
        guard !price.isEmpty else { return nil }
        let normalizedPrice = price.replacingOccurrences(of: ",", with: ".")
        guard let decimal = Decimal(string: normalizedPrice) else { return nil }
        return decimal
    }

    func showValidationToast() {
        if !isPriceValid {
            toast = ToastMessage("Precio no válido", type: .warning)
        }
    }

    func resolvedDescriptionForSave() -> String {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDescription.isEmpty {
            return trimmedDescription
        }

        let fallback = lastUsedConcept ?? selectedCategory?.name ?? "Concepto"
        description = fallback
        return fallback
    }

    // MARK: - Public Methods

    func configure(defaultGroup: SDGroup, availableGroups: [SDGroup]) {
        if selectedGroup == nil {
            selectedGroup = defaultGroup
        }
        self.availableGroups = availableGroups.isEmpty ? [defaultGroup] : availableGroups
    }

    func loadOptionsForSelectedGroup() async {
        guard let groupId = selectedGroup?.id else { return }
        let shouldRestoreEditSelections = isEditMode && !hasLoadedFormData
        await loadOptions(forGroupId: groupId, restoringEditSelections: shouldRestoreEditSelections)
        hasLoadedFormData = true
    }

    func loadOptions(forGroupId groupId: UUID, restoringEditSelections: Bool) async {
        isLoading = true
        errorMessage = nil

        do {
            let categories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
            let paymentMethods = try await fetchPaymentMethodsUseCase.executeActive(forGroupId: groupId)
            self.categories = categories
            self.paymentMethods = paymentMethods

            if restoringEditSelections {
                selectedCategory = categories.first { $0.id == itemListToEdit?.category?.id }
                selectedPaymentMethod = paymentMethods.first { $0.id == itemListToEdit?.paymentMethod?.id }
            } else {
                selectedCategory = preferredCategoryId.flatMap { preferredId in
                    categories.first { $0.id == preferredId }
                }
                selectedPaymentMethod = nil
            }

            updateSuggestions()
        } catch {
            errorMessage = "Error al cargar datos del formulario: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadUsageMemory(forGroupId groupId: UUID) async {
        didManuallyChoosePaymentMethod = false
        let persistedLastUsed = await loadLastUsedSelectionIds(forGroupId: groupId)
        lastUsedCategoryIds = storedCategoryIds(forGroupId: groupId)
        if lastUsedCategoryIds.isEmpty, let categoryId = persistedLastUsed.categoryId {
            lastUsedCategoryIds = [categoryId]
        }
        lastUsedPaymentMethodId = persistedLastUsed.hasHistory
            ? persistedLastUsed.paymentMethodId
            : storedPaymentMethodId(forGroupId: groupId)
    }

    func resolveUsageMemory(forGroupId groupId: UUID) async -> (categoryIds: [UUID], paymentMethodId: UUID?) {
        let persistedLastUsed = await loadLastUsedSelectionIds(forGroupId: groupId)
        var categoryIds = storedCategoryIds(forGroupId: groupId)
        if categoryIds.isEmpty, let categoryId = persistedLastUsed.categoryId {
            categoryIds = [categoryId]
        }
        let paymentMethodId = persistedLastUsed.hasHistory
            ? persistedLastUsed.paymentMethodId
            : storedPaymentMethodId(forGroupId: groupId)
        return (categoryIds, paymentMethodId)
    }

    func recordCategoryUsage(_ category: SDCategory, forGroupId groupId: UUID) {
        var ids = lastUsedCategoryIds
        ids.removeAll { $0 == category.id }
        ids.insert(category.id, at: 0)
        ids = Array(ids.prefix(categoryUsageLimit))
        lastUsedCategoryIds = ids

        let stored = ids.map { $0.uuidString }.joined(separator: ",")
        UserDefaults.standard.set(stored, forKey: categoryUsageKey(forGroupId: groupId))
    }

    func recordPaymentMethodUsage(_ paymentMethod: SDPaymentMethod, forGroupId groupId: UUID) {
        didManuallyChoosePaymentMethod = true
        lastUsedPaymentMethodId = paymentMethod.id
        UserDefaults.standard.set(paymentMethod.id.uuidString, forKey: paymentMethodUsageKey(forGroupId: groupId))
    }

    func deselectPaymentMethodManually() {
        didManuallyChoosePaymentMethod = true
        selectedPaymentMethod = nil
    }

    func orderedCategoriesByUsage() -> [SDCategory] {
        categories.sorted {
            chipRank($0.id, lastUsed: lastUsedCategoryIds) <
            chipRank($1.id, lastUsed: lastUsedCategoryIds)
        }
    }

    func orderedCategoriesByUsage(lastUsedCategoryIds: [UUID]) -> [SDCategory] {
        categories.sorted {
            chipRank($0.id, lastUsed: lastUsedCategoryIds) <
            chipRank($1.id, lastUsed: lastUsedCategoryIds)
        }
    }

    func orderedPaymentMethodsByUsage() -> [SDPaymentMethod] {
        paymentMethods.sorted {
            chipRank($0.id, lastUsed: lastUsedPaymentMethodId) <
            chipRank($1.id, lastUsed: lastUsedPaymentMethodId)
        }
    }

    func orderedPaymentMethodsByUsage(lastUsedPaymentMethodId: UUID?) -> [SDPaymentMethod] {
        paymentMethods.sorted {
            chipRank($0.id, lastUsed: lastUsedPaymentMethodId) <
            chipRank($1.id, lastUsed: lastUsedPaymentMethodId)
        }
    }

    private func loadLastUsedSelectionIds(forGroupId groupId: UUID) async -> (categoryId: UUID?, paymentMethodId: UUID?, hasHistory: Bool) {
        do {
            let snapshots = try await loadUsageMemorySnapshots(forGroupId: groupId)
            usageMemorySnapshots = snapshots
            let lastRegistered = snapshots.max { $0.createdAt < $1.createdAt }
            return (
                snapshots.first { $0.categoryId != nil }?.categoryId,
                lastRegistered?.paymentMethodId,
                lastRegistered != nil
            )
        } catch {
            usageMemorySnapshots = []
            return (nil, nil, false)
        }
    }

    private func loadUsageMemorySnapshots(forGroupId groupId: UUID) async throws -> [UsageMemorySnapshot] {
        let key = usageMemoryCacheKey(forGroupId: groupId)
        if let cached: [UsageMemorySnapshot] = cacheManager.getCachedData(for: key) {
            return cached
        }

        let itemLists = try await fetchItemListsUseCase.execute(forGroupId: groupId)
        let snapshots = itemLists.map {
            UsageMemorySnapshot(
                itemListDescription: $0.itemListDescription,
                createdAt: $0.createdAt,
                categoryId: $0.category?.id,
                paymentMethodId: $0.paymentMethod?.id
            )
        }
        cacheManager.cacheData(snapshots, for: key)
        return snapshots
    }

    private func clearUsageMemoryCache(forGroupId groupId: UUID) {
        cacheManager.clearDataCache(for: usageMemoryCacheKey(forGroupId: groupId))
    }

    private func usageMemoryCacheKey(forGroupId groupId: UUID) -> String {
        "quick_add_usage_memory_\(groupId.uuidString)"
    }

    private func storedCategoryIds(forGroupId groupId: UUID) -> [UUID] {
        UserDefaults.standard
            .string(forKey: categoryUsageKey(forGroupId: groupId))
            .map { $0.components(separatedBy: ",").compactMap { UUID(uuidString: $0) } }
            ?? []
    }

    private func storedPaymentMethodId(forGroupId groupId: UUID) -> UUID? {
        UserDefaults.standard
            .string(forKey: paymentMethodUsageKey(forGroupId: groupId))
            .flatMap { UUID(uuidString: $0) }
    }

    private func categoryUsageKey(forGroupId groupId: UUID) -> String {
        "lastUsedCategoryIds_\(groupId.uuidString)"
    }

    private func paymentMethodUsageKey(forGroupId groupId: UUID) -> String {
        "lastUsedPaymentMethodId_\(groupId.uuidString)"
    }

    private func chipRank(_ id: UUID, lastUsed: [UUID]) -> Int {
        lastUsed.firstIndex(of: id) ?? lastUsed.count
    }

    private func chipRank(_ id: UUID, lastUsed: UUID?) -> Int {
        id == lastUsed ? 0 : 1
    }

    func loadCategories(forGroupId groupId: UUID, lastUsedCategoryId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            categories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
            if isEditMode {
                selectedCategory = categories.first { $0.id == itemListToEdit?.category?.id }
            } else {
                selectedCategory = nil
            }
            updateSuggestions()
        } catch {
            errorMessage = "Error al cargar categorías: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadPaymentMethods(forGroupId groupId: UUID, lastUsedPaymentMethodId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            paymentMethods = try await fetchPaymentMethodsUseCase.executeActive(forGroupId: groupId)
            if isEditMode {
                selectedPaymentMethod = paymentMethods.first { $0.id == itemListToEdit?.paymentMethod?.id }
            } else {
                selectedPaymentMethod = nil
            }
        } catch {
            errorMessage = "Error al cargar métodos de pago: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func createItemList(
        description: String,
        date: Date,
        categoryId: UUID,
        groupId: UUID,
        paymentMethodId: UUID?
    ) async -> SDItemList? {
        isLoading = true
        errorMessage = nil

        do {
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

            let itemList = try await createItemListUseCase.execute(
                description: trimmedDescription,
                date: date,
                categoryId: categoryId,
                paymentMethodId: paymentMethodId,
                groupId: groupId
            )

            if let priceDecimal = priceAsDecimal {
                let isFuture = Calendar.current.startOfDay(for: date) > Calendar.current.startOfDay(for: Date())
                let _ = try await createItemUseCase.execute(
                    description: trimmedDescription,
                    amount: priceDecimal,
                    quantity: 1,
                    itemListId: itemList.id,
                    isPaid: !isFuture
                )
            }

            clearUsageMemoryCache(forGroupId: groupId)
            isLoading = false
            return itemList
        } catch {
            errorMessage = "Error al crear gasto: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }

    func updateItemList(groupId: UUID) async -> SDItemList? {
        guard let toEdit = itemListToEdit else { return nil }
        isLoading = true
        errorMessage = nil

        if let newCategory = selectedCategory,
           newCategory.id != toEdit.category?.id,
           let oldCategoryName = toEdit.category?.name,
           toEdit.items.count == 1,
           let item = toEdit.items.first,
           toEdit.itemListDescription == oldCategoryName,
           item.itemDescription == oldCategoryName {
            description = newCategory.name
            item.itemDescription = newCategory.name
        }

        let newDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let oldDescription = toEdit.itemListDescription

        // If the item list has exactly one item whose name matches the old list name,
        // keep them in sync when the user renames the list.
        if newDescription != oldDescription,
           toEdit.items.count == 1,
           let singleItem = toEdit.items.first,
           singleItem.itemDescription == oldDescription {
            singleItem.itemDescription = newDescription
        }

        toEdit.itemListDescription = newDescription
        toEdit.date = date
        if let category = selectedCategory { toEdit.category = category }
        toEdit.paymentMethod = selectedPaymentMethod
        if let group = selectedGroup { toEdit.group = group }

        do {
            try await updateItemListUseCase.execute(toEdit)
            isLoading = false
            return toEdit
        } catch {
            errorMessage = "Error al actualizar: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }

    func validateAndCorrectPrice() {
        price = correctPriceInput(price)
    }

    func pastePrice() {
        guard let raw = UIPasteboard.general.string else { return }
        price = correctPriceInput(raw)
    }

    // MARK: - Private Methods

    private func correctPriceInput(_ input: String) -> String {
        if input.isEmpty { return input }

        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
        var filtered = input.filter { char in
            return char.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
        }

        filtered = filtered.replacingOccurrences(of: ",", with: ".")

        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            filtered = components[0] + "." + components[1...].joined()
        }

        let parts = filtered.components(separatedBy: ".")
        var integerPart = parts[0]
        var decimalPart = parts.count > 1 ? parts[1] : ""

        if integerPart.count > 7 {
            integerPart = String(integerPart.prefix(7))
        }

        if decimalPart.count > 2 {
            decimalPart = String(decimalPart.prefix(2))
        }

        if parts.count > 1 {
            return integerPart + "." + decimalPart
        } else {
            return integerPart
        }
    }

    func updateSuggestions() {
        suggestions = ConceptSuggestionEngine.getSuggestions(
            query: description,
            amount: priceAsDecimal.map { Double(truncating: $0 as NSDecimalNumber) },
            forCategory: selectedCategory,
            allCategories: categories
        )
        lastUsedConcept = ConceptSuggestionEngine.lastUsed(forCategory: selectedCategory)
    }

    func updateConceptAssists() {
        updateSuggestions()
        applyPaymentMethodSuggestionForCurrentConcept()
    }

    func applySuggestion(_ suggestion: ConceptSuggestion, forGroupId groupId: UUID) {
        description = suggestion.description
        if suggestion.category.id != selectedCategory?.id {
            selectedCategory = suggestion.category
            recordCategoryUsage(suggestion.category, forGroupId: groupId)
        }
        updateConceptAssists()
    }

    private func applyPaymentMethodSuggestionForCurrentConcept() {
        guard !isEditMode, !didManuallyChoosePaymentMethod else { return }
        guard let selectedCategory else { return }

        let normalizedDescription = normalizedConcept(description)
        guard !normalizedDescription.isEmpty else { return }

        let matchingSnapshot = usageMemorySnapshots
            .filter {
                $0.categoryId == selectedCategory.id &&
                normalizedConcept($0.itemListDescription) == normalizedDescription
            }
            .max { $0.createdAt < $1.createdAt }

        guard let paymentMethodId = matchingSnapshot?.paymentMethodId else { return }

        selectedPaymentMethod = paymentMethods.first { $0.id == paymentMethodId }
        lastUsedPaymentMethodId = selectedPaymentMethod?.id
    }

    private func normalizedConcept(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    func clearError() {
        errorMessage = nil
    }
}
