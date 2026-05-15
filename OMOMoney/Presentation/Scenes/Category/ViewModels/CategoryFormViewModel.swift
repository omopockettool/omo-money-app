import Foundation

@MainActor
@Observable
final class CategoryFormViewModel {

    var isLoading = false
    var errorMessage: String?
    var showError = false

    private let createCategoryUseCase: CreateCategoryUseCase
    private let updateCategoryUseCase: UpdateCategoryUseCase

    init(createCategoryUseCase: CreateCategoryUseCase, updateCategoryUseCase: UpdateCategoryUseCase) {
        self.createCategoryUseCase = createCategoryUseCase
        self.updateCategoryUseCase = updateCategoryUseCase
    }

    convenience init() {
        let container = AppDIContainer.shared
        self.init(
            createCategoryUseCase: container.makeCreateCategoryUseCase(),
            updateCategoryUseCase: container.makeUpdateCategoryUseCase()
        )
    }

    /// Returns the saved SDCategory on success, nil on failure.
    func save(name: String, color: String, icon: String, groupId: UUID, limit: Decimal?, categoryToEdit: SDCategory?) async -> SDCategory? {
        isLoading = true
        errorMessage = nil
        showError = false
        defer { isLoading = false }

        do {
            if let category = categoryToEdit {
                try await updateCategoryUseCase.execute(
                    categoryId: category.id,
                    name: name,
                    icon: icon,
                    color: color,
                    limit: limit,
                    limitFrequency: nil
                )
                return category
            } else {
                return try await createCategoryUseCase.execute(
                    name: name,
                    color: color,
                    icon: icon,
                    groupId: groupId,
                    limit: limit,
                    limitFrequency: nil
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return nil
        }
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}
