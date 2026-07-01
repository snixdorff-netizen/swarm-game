import XCTest
@testable import SWARM

final class MetaStoreTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: MetaStore!

    override func setUp() {
        super.setUp()
        suiteName = "SWARMTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        store = MetaStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        suiteName = nil
        defaults = nil
        store = nil
        super.tearDown()
    }

    func testAwardRunGrantsCores() {
        store.awardRun(kills: 10, timeSec: 60)
        // kills + max(1, timeSec/12) = 10 + 5 = 15
        XCTAssertEqual(store.cores, 15)
    }

    func testAwardRunUpdatesBestTime() {
        store.awardRun(kills: 0, timeSec: 42)
        XCTAssertEqual(store.bestTime, 42)

        store.awardRun(kills: 0, timeSec: 30)
        XCTAssertEqual(store.bestTime, 42)

        let newBest = store.awardRun(kills: 0, timeSec: 99)
        XCTAssertTrue(newBest)
        XCTAssertEqual(store.bestTime, 99)
    }

    func testBestTimePersistsAcrossInstances() {
        store.awardRun(kills: 1, timeSec: 77)
        let reloaded = MetaStore(defaults: defaults)
        XCTAssertEqual(reloaded.bestTime, 77)
    }

    func testBuyUpgradeDeductsCoresAndIncrementsLevel() {
        store.awardRun(kills: 100, timeSec: 120)
        let coresBefore = store.cores
        let upgrade = MetaCatalog.all.first { $0.id == "meta_dmg" }!
        let cost = upgrade.cost(0)

        XCTAssertTrue(store.canBuy(upgrade))
        XCTAssertTrue(store.buy(upgrade))

        XCTAssertEqual(store.level(for: upgrade.id), 1)
        XCTAssertEqual(store.cores, coresBefore - cost)
    }

    func testBuyUpgradeFailsWhenInsufficientCores() {
        let upgrade = MetaCatalog.all.first { $0.id == "meta_dmg" }!
        XCTAssertFalse(store.canBuy(upgrade))
        XCTAssertFalse(store.buy(upgrade))
        XCTAssertEqual(store.level(for: upgrade.id), 0)
    }

    func testDamageMultScalesWithMetaDamage() {
        XCTAssertEqual(store.damageMult, 1.0, accuracy: 0.0001)

        store.awardRun(kills: 200, timeSec: 300)
        let upgrade = MetaCatalog.all.first { $0.id == "meta_dmg" }!
        _ = store.buy(upgrade)
        _ = store.buy(upgrade)

        XCTAssertEqual(store.damageMult, 1.08, accuracy: 0.0001)
    }
}