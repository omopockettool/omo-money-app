import XCTest
@testable import OMOMoney

/// Verifies that FetchCategoriesUseCase scopes results to the requested group,
/// which also validates the #Predicate optimisation in CategoryPickerView.
@MainActor
final class FetchCategoriesUseCaseTests: XCTestCase {

    private var swiftData: SwiftDataTestContainer!
    private var useCase: FetchCategoriesUseCase!

    override func setUp() async throws {
        swiftData = try SwiftDataTestContainer()
        useCase = DefaultFetchCategoriesUseCase(categoryRepository: swiftData.makeCategoryRepository())
    }

    override func tearDown() {
        useCase = nil
        swiftData = nil
    }

    // MARK: - Scope

    func testFetch_ReturnsOnlyTargetGroupCategories() async throws {
        let groupA = try swiftData.insertGroup(name: "A")
        let groupB = try swiftData.insertGroup(name: "B")
        _ = try swiftData.insertCategory(name: "Food", group: groupA)
        _ = try swiftData.insertCategory(name: "Transport", group: groupA)
        _ = try swiftData.insertCategory(name: "Work", group: groupB)

        let results = try await useCase.execute(forGroupId: groupA.id)

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.group?.id == groupA.id })
    }

    func testFetch_DoesNotReturnOtherGroupCategories() async throws {
        let groupA = try swiftData.insertGroup(name: "A")
        let groupB = try swiftData.insertGroup(name: "B")
        _ = try swiftData.insertCategory(name: "OnlyInB", group: groupB)

        let results = try await useCase.execute(forGroupId: groupA.id)

        XCTAssertTrue(results.isEmpty)
    }

    func testFetch_EmptyForFreshGroup() async throws {
        let group = try swiftData.insertGroup()

        let results = try await useCase.execute(forGroupId: group.id)

        XCTAssertTrue(results.isEmpty)
    }

    func testFetch_ReturnsAllCategoriesForGroup() async throws {
        let group = try swiftData.insertGroup()
        _ = try swiftData.insertCategory(name: "Alpha", group: group)
        _ = try swiftData.insertCategory(name: "Beta", group: group)
        _ = try swiftData.insertCategory(name: "Gamma", group: group)

        let results = try await useCase.execute(forGroupId: group.id)

        XCTAssertEqual(results.count, 3)
    }

    func testFetch_ResultsSortedByName() async throws {
        let group = try swiftData.insertGroup()
        _ = try swiftData.insertCategory(name: "Zapatos", group: group)
        _ = try swiftData.insertCategory(name: "Alquiler", group: group)
        _ = try swiftData.insertCategory(name: "Comida", group: group)

        let results = try await useCase.execute(forGroupId: group.id)

        XCTAssertEqual(results.map(\.name), ["Alquiler", "Comida", "Zapatos"])
    }
}
