import XCTest
@testable import OMOMoney

@MainActor
final class CreateItemUseCaseTests: XCTestCase {

    private var swiftData: SwiftDataTestContainer!
    private var useCase: CreateItemUseCase!
    private var group: SDGroup!
    private var itemList: SDItemList!

    override func setUp() async throws {
        swiftData = try SwiftDataTestContainer()
        useCase = DefaultCreateItemUseCase(itemRepository: swiftData.makeItemRepository())
        group = try swiftData.insertGroup()
        itemList = try swiftData.insertItemList(group: group)
    }

    override func tearDown() {
        useCase = nil
        itemList = nil
        group = nil
        swiftData = nil
    }

    // MARK: - Success

    func testCreate_ValidData_ReturnsItem() async throws {
        let item = try await useCase.execute(
            description: "Café",
            amount: 2.50,
            quantity: 1,
            itemListId: itemList.id,
            isPaid: false
        )

        XCTAssertEqual(item.itemDescription, "Café")
        XCTAssertEqual(item.amount, 2.50)
        XCTAssertEqual(item.quantity, 1)
        XCTAssertFalse(item.isPaid)
    }

    func testCreate_TrimsWhitespaceFromDescription() async throws {
        let item = try await useCase.execute(
            description: "  Pizza  ",
            amount: 12.0,
            quantity: 1,
            itemListId: itemList.id,
            isPaid: false
        )

        XCTAssertEqual(item.itemDescription, "Pizza")
    }

    func testCreate_ZeroAmount_Succeeds() async throws {
        let item = try await useCase.execute(
            description: "Gratis",
            amount: 0.0,
            quantity: 1,
            itemListId: itemList.id,
            isPaid: false
        )

        XCTAssertEqual(item.amount, 0.0)
    }

    func testCreate_MultipleQuantity_TotalAmountIsCorrect() async throws {
        let item = try await useCase.execute(
            description: "Agua",
            amount: 1.50,
            quantity: 3,
            itemListId: itemList.id,
            isPaid: false
        )

        XCTAssertEqual(item.totalAmount, 4.50, accuracy: 0.001)
    }

    func testCreate_IsPaidTrue_PersistsCorrectly() async throws {
        let item = try await useCase.execute(
            description: "Alquiler",
            amount: 800.0,
            quantity: 1,
            itemListId: itemList.id,
            isPaid: true
        )

        XCTAssertTrue(item.isPaid)
    }

    // MARK: - Validation

    func testCreate_EmptyDescription_ThrowsInvalidDescription() async {
        do {
            _ = try await useCase.execute(
                description: "",
                amount: 5.0,
                quantity: 1,
                itemListId: itemList.id,
                isPaid: false
            )
            XCTFail("Expected ValidationError.invalidDescription")
        } catch ValidationError.invalidDescription {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreate_WhitespaceOnlyDescription_ThrowsInvalidDescription() async {
        do {
            _ = try await useCase.execute(
                description: "   ",
                amount: 5.0,
                quantity: 1,
                itemListId: itemList.id,
                isPaid: false
            )
            XCTFail("Expected ValidationError.invalidDescription")
        } catch ValidationError.invalidDescription {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreate_NegativeAmount_ThrowsInvalidAmount() async {
        do {
            _ = try await useCase.execute(
                description: "Item",
                amount: -1.0,
                quantity: 1,
                itemListId: itemList.id,
                isPaid: false
            )
            XCTFail("Expected ValidationError.invalidAmount")
        } catch ValidationError.invalidAmount {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreate_ZeroQuantity_ThrowsInvalidQuantity() async {
        do {
            _ = try await useCase.execute(
                description: "Item",
                amount: 5.0,
                quantity: 0,
                itemListId: itemList.id,
                isPaid: false
            )
            XCTFail("Expected ValidationError.invalidQuantity")
        } catch ValidationError.invalidQuantity {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreate_NegativeQuantity_ThrowsInvalidQuantity() async {
        do {
            _ = try await useCase.execute(
                description: "Item",
                amount: 5.0,
                quantity: -2,
                itemListId: itemList.id,
                isPaid: false
            )
            XCTFail("Expected ValidationError.invalidQuantity")
        } catch ValidationError.invalidQuantity {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreate_NilItemListId_ThrowsError() async {
        do {
            _ = try await useCase.execute(
                description: "Item",
                amount: 5.0,
                quantity: 1,
                itemListId: nil,
                isPaid: false
            )
            XCTFail("Expected error for nil itemListId")
        } catch {
            // any error is acceptable
        }
    }
}
