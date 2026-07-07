import XCTest
@testable import Ream

final class ReamTests: XCTestCase {
    var store: ReamStore!

    @MainActor
    override func setUp() {
        super.setUp()
        store = ReamStore()
        store.deleteAllData()
        for k in store.kids { store.deleteKid(k.id) }
    }

    // MARK: - Kids

    @MainActor
    func testAddKid() {
        let added = store.addKid(name: "Alex", isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.kids.count, 1)
        XCTAssertEqual(store.kids[0].name, "Alex")
    }

    @MainActor
    func testAddKidRejectsEmptyName() {
        let added = store.addKid(name: "   ", isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testFreeLimitBlocksSecondKid() {
        _ = store.addKid(name: "Alex", isPro: false)
        XCTAssertFalse(store.canAddKid(isPro: false))
        let second = store.addKid(name: "Jamie", isPro: false)
        XCTAssertFalse(second)
        XCTAssertEqual(store.kids.count, 1)
    }

    @MainActor
    func testProAllowsMultipleKids() {
        _ = store.addKid(name: "Alex", isPro: true)
        let second = store.addKid(name: "Jamie", isPro: true)
        XCTAssertTrue(second)
        XCTAssertEqual(store.kids.count, 2)
    }

    @MainActor
    func testRenameKid() {
        _ = store.addKid(name: "Alex", isPro: false)
        let id = store.kids[0].id
        store.renameKid(id, name: "Alexander")
        XCTAssertEqual(store.kids[0].name, "Alexander")
    }

    @MainActor
    func testDeleteKidRemovesTheirSupplies() {
        _ = store.addKid(name: "Alex", isPro: false)
        let kidID = store.kids[0].id
        _ = store.addSupply(kidID: kidID, name: "Pencils", kind: .pencil, isPro: false)
        XCTAssertEqual(store.items.count, 1)
        store.deleteKid(kidID)
        XCTAssertTrue(store.kids.isEmpty)
        XCTAssertTrue(store.items.isEmpty)
    }

    // MARK: - Supplies

    @MainActor
    func testAddSupply() {
        _ = store.addKid(name: "Alex", isPro: false)
        let kidID = store.kids[0].id
        let added = store.addSupply(kidID: kidID, name: "Glue Stick", kind: .glueStick, isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.supplies(for: kidID).count, 1)
        XCTAssertEqual(store.supplies(for: kidID)[0].level, 1.0)
    }

    @MainActor
    func testFreeSupplyLimit() {
        _ = store.addKid(name: "Alex", isPro: true)
        let kidID = store.kids[0].id
        for i in 0..<ReamStore.freeSupplyLimit {
            XCTAssertTrue(store.addSupply(kidID: kidID, name: "Item \(i)", kind: .pencil, isPro: false))
        }
        XCTAssertFalse(store.canAddSupply(isPro: false))
        let overflow = store.addSupply(kidID: kidID, name: "One Too Many", kind: .pencil, isPro: false)
        XCTAssertFalse(overflow)
        XCTAssertEqual(store.items.count, ReamStore.freeSupplyLimit)
    }

    @MainActor
    func testProAllowsUnlimitedSupplies() {
        _ = store.addKid(name: "Alex", isPro: true)
        let kidID = store.kids[0].id
        for i in 0..<(ReamStore.freeSupplyLimit + 3) {
            XCTAssertTrue(store.addSupply(kidID: kidID, name: "Item \(i)", kind: .pencil, isPro: true))
        }
        XCTAssertEqual(store.items.count, ReamStore.freeSupplyLimit + 3)
    }

    @MainActor
    func testUseSupplyReducesLevel() {
        _ = store.addKid(name: "Alex", isPro: false)
        let kidID = store.kids[0].id
        _ = store.addSupply(kidID: kidID, name: "Pencils", kind: .pencil, isPro: false)
        let id = store.items[0].id
        store.useSupply(id)
        XCTAssertLessThan(store.items[0].level, 1.0)
    }

    @MainActor
    func testUseSupplyNeverGoesBelowZero() {
        _ = store.addKid(name: "Alex", isPro: false)
        let kidID = store.kids[0].id
        _ = store.addSupply(kidID: kidID, name: "Glue Stick", kind: .glueStick, isPro: false)
        let id = store.items[0].id
        for _ in 0..<50 { store.useSupply(id) }
        XCTAssertEqual(store.items[0].level, 0.0)
        XCTAssertTrue(store.items[0].isEmpty)
    }

    @MainActor
    func testRestockResetsToFull() {
        _ = store.addKid(name: "Alex", isPro: false)
        let kidID = store.kids[0].id
        _ = store.addSupply(kidID: kidID, name: "Pencils", kind: .pencil, isPro: false)
        let id = store.items[0].id
        store.useSupply(id)
        store.restockSupply(id)
        XCTAssertEqual(store.items[0].level, 1.0)
    }

    @MainActor
    func testDeleteSupply() {
        _ = store.addKid(name: "Alex", isPro: false)
        let kidID = store.kids[0].id
        _ = store.addSupply(kidID: kidID, name: "Pencils", kind: .pencil, isPro: false)
        let id = store.items[0].id
        store.deleteSupply(id)
        XCTAssertTrue(store.items.isEmpty)
    }

    @MainActor
    func testUpdateSupply() {
        _ = store.addKid(name: "Alex", isPro: false)
        let kidID = store.kids[0].id
        _ = store.addSupply(kidID: kidID, name: "Pencils", kind: .pencil, isPro: false)
        let id = store.items[0].id
        store.updateSupply(id, name: "Colored Pencils", kind: .crayon, restockThreshold: 0.5)
        XCTAssertEqual(store.items[0].name, "Colored Pencils")
        XCTAssertEqual(store.items[0].kind, .crayon)
        XCTAssertEqual(store.items[0].restockThreshold, 0.5)
    }

    @MainActor
    func testNeedsRestockFlag() {
        var item = SupplyItem(kidID: UUID(), name: "Test", kind: .pencil, level: 0.2, restockThreshold: 0.25)
        XCTAssertTrue(item.needsRestock)
        item.level = 0.5
        XCTAssertFalse(item.needsRestock)
    }

    @MainActor
    func testRestockNeededCountAcrossKids() {
        _ = store.addKid(name: "Alex", isPro: true)
        let kidID = store.kids[0].id
        _ = store.addSupply(kidID: kidID, name: "Pencils", kind: .pencil, isPro: true)
        _ = store.addSupply(kidID: kidID, name: "Glue", kind: .glueStick, isPro: true)
        let id0 = store.items[0].id
        for _ in 0..<20 { store.useSupply(id0) }
        XCTAssertEqual(store.restockNeededCount, 1)
    }

    // MARK: - Model-level use() / kind increments

    func testPencilUsesSlowerThanGlueStick() {
        var pencil = SupplyItem(kidID: UUID(), name: "P", kind: .pencil)
        var glue = SupplyItem(kidID: UUID(), name: "G", kind: .glueStick)
        pencil.use()
        glue.use()
        XCTAssertGreaterThan(pencil.level, glue.level)
    }
}
