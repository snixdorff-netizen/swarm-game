import XCTest
@testable import SWARM

final class MetaStoreTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: MetaStore!

    override func setUp() {
        super.setUp()
        suiteName = "SWARMTests.\(UUID().uuidString)"
        guard let suite = UserDefaults(suiteName: suiteName) else {
            XCTFail("failed to create UserDefaults suite")
            return
        }
        defaults = suite
        store = MetaStore(defaults: defaults)
    }

    override func tearDown() {
        if let suiteName { defaults?.removePersistentDomain(forName: suiteName) }
        suiteName = nil
        defaults = nil
        store = nil
        super.tearDown()
    }

    private func upgrade(_ id: String, file: StaticString = #file, line: UInt = #line) -> MetaUpgrade {
        guard let up = MetaCatalog.all.first(where: { $0.id == id }) else {
            XCTFail("missing upgrade \(id)", file: file, line: line)
            fatalError()
        }
        return up
    }

    private func reloadStore() -> MetaStore {
        MetaStore(defaults: defaults)
    }

    func testAwardRunGrantsCores() {
        store.awardRun(kills: 10, timeSec: 60)
        XCTAssertEqual(store.cores, 15)
    }

    func testAwardRunUpdatesBestTime() {
        store.awardRun(kills: 0, timeSec: 42)
        XCTAssertEqual(store.bestTime, 42)

        XCTAssertFalse(store.awardRun(kills: 0, timeSec: 30))
        XCTAssertEqual(store.bestTime, 42)

        XCTAssertFalse(store.awardRun(kills: 0, timeSec: 42))
        XCTAssertEqual(store.bestTime, 42)

        XCTAssertTrue(store.awardRun(kills: 0, timeSec: 99))
        XCTAssertEqual(store.bestTime, 99)
    }

    func testAwardRunZeroTimeDoesNotSetBest() {
        XCTAssertFalse(store.awardRun(kills: 0, timeSec: 0))
        XCTAssertEqual(store.bestTime, 0)
        XCTAssertEqual(store.cores, 1)
    }

    func testCoresFormulaBoundaries() {
        store.awardRun(kills: 0, timeSec: 0)
        XCTAssertEqual(store.cores, 1)

        defaults.removePersistentDomain(forName: suiteName)
        store = MetaStore(defaults: defaults)
        store.awardRun(kills: 0, timeSec: 11)
        XCTAssertEqual(store.cores, 1)

        defaults.removePersistentDomain(forName: suiteName)
        store = MetaStore(defaults: defaults)
        store.awardRun(kills: 0, timeSec: 12)
        XCTAssertEqual(store.cores, 1)

        defaults.removePersistentDomain(forName: suiteName)
        store = MetaStore(defaults: defaults)
        store.awardRun(kills: 0, timeSec: 24)
        XCTAssertEqual(store.cores, 2)
    }

    func testCoresForRunMatchesAwardRun() {
        let earned = MetaStore.coresForRun(kills: 7, timeSec: 48)
        XCTAssertEqual(earned, 11)
        store.awardRun(kills: 7, timeSec: 48)
        XCTAssertEqual(store.cores, 11)
    }

    func testBestTimePersistsAcrossInstances() {
        store.awardRun(kills: 1, timeSec: 77)
        XCTAssertEqual(reloadStore().bestTime, 77)
    }

    func testCoresAndLevelsPersistAcrossInstances() {
        store.awardRun(kills: 50, timeSec: 60)
        let coresAfterRun = store.cores
        _ = store.buy(upgrade("meta_hp"))
        let reloaded = reloadStore()
        XCTAssertEqual(reloaded.cores, coresAfterRun - upgrade("meta_hp").cost(0))
        XCTAssertEqual(reloaded.level(for: "meta_hp"), 1)
    }

    func testBuyUpgradeDeductsCoresAndIncrementsLevel() {
        store.awardRun(kills: 100, timeSec: 120)
        let coresBefore = store.cores
        let up = upgrade("meta_dmg")
        let cost = up.cost(0)

        XCTAssertTrue(store.canBuy(up))
        XCTAssertTrue(store.buy(up))

        XCTAssertEqual(store.level(for: up.id), 1)
        XCTAssertEqual(store.cores, coresBefore - cost)
    }

    func testBuyUpgradeFailsWhenInsufficientCores() {
        let up = upgrade("meta_dmg")
        XCTAssertFalse(store.canBuy(up))
        XCTAssertFalse(store.buy(up))
        XCTAssertEqual(store.level(for: up.id), 0)
    }

    func testBuyFailsAtMaxLevel() {
        store.awardRun(kills: 500, timeSec: 600)
        let up = upgrade("meta_dmg")
        while store.level(for: up.id) < up.maxLevel {
            XCTAssertTrue(store.buy(up))
        }
        XCTAssertFalse(store.canBuy(up))
        XCTAssertFalse(store.buy(up))
        XCTAssertEqual(store.level(for: up.id), up.maxLevel)
    }

    func testDamageMultScalesWithMetaDamage() {
        XCTAssertEqual(store.damageMult, 1.0, accuracy: 0.0001)

        store.awardRun(kills: 200, timeSec: 300)
        let up = upgrade("meta_dmg")
        _ = store.buy(up)
        _ = store.buy(up)

        XCTAssertEqual(store.damageMult, 1.08, accuracy: 0.0001)
    }

    func testBonusHpSpeedMagnetScale() {
        store.awardRun(kills: 500, timeSec: 600)
        _ = store.buy(upgrade("meta_hp"))
        _ = store.buy(upgrade("meta_hp"))
        _ = store.buy(upgrade("meta_speed"))
        _ = store.buy(upgrade("meta_speed"))
        _ = store.buy(upgrade("meta_magnet"))
        _ = store.buy(upgrade("meta_magnet"))

        XCTAssertEqual(store.bonusHp, 16, accuracy: 0.0001)
        XCTAssertEqual(store.speedMult, 1.06, accuracy: 0.0001)
        XCTAssertEqual(store.bonusMagnet, 12, accuracy: 0.0001)
    }

    func testCorruptMetaLevelsResetsToEmpty() {
        defaults.set("bad-data", forKey: "swarm_meta_levels")
        let reloaded = MetaStore(defaults: defaults)
        XCTAssertEqual(reloaded.level(for: "meta_dmg"), 0)
    }

    func testCanBuyEachCatalogEntry() {
        store.awardRun(kills: 500, timeSec: 600)
        for up in MetaCatalog.all {
            let coresBefore = store.cores
            let cost = up.cost(0)
            XCTAssertTrue(store.canBuy(up), "expected canBuy for \(up.id)")
            XCTAssertTrue(store.buy(up), "expected buy for \(up.id)")
            XCTAssertEqual(store.level(for: up.id), 1)
            XCTAssertEqual(store.cores, coresBefore - cost)
        }
    }
}