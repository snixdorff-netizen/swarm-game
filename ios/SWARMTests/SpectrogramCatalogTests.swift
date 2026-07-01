import XCTest
@testable import SWARM

final class SpectrogramCatalogTests: XCTestCase {
    private var woodThrush: ProjectSpecies { ProjectSpeciesCatalog.with(id: "wood_thrush")! }
    private var littleBrownBat: ProjectSpecies { ProjectSpeciesCatalog.with(id: "little_brown_bat")! }

    func testSpectrogramMidBandDominatesPasserineSM5() {
        let snap = SpectrogramBuilder.snapshot(nearby: [woodThrush, woodThrush], deployMode: .sm5)
        let mid = snap.bands.first { $0.id == "mid" }!
        let ultra = snap.bands.first { $0.id == "ultra" }!
        XCTAssertGreaterThan(mid.level, ultra.level)
        XCTAssertTrue(snap.dominantLabel?.contains("Wood Thrush") == true)
        XCTAssertEqual(snap.waterfall.timeSteps, SpectrogramWaterfall.defaultTimeSteps)
        XCTAssertEqual(snap.waterfall.energy.count, snap.waterfall.timeSteps * snap.waterfall.freqBins)
    }

    func testSpectrogramUltraBoostedOnSM5BAT() {
        let acoustic = SpectrogramBuilder.snapshot(nearby: [woodThrush], deployMode: .sm5bat)
        let endangered = SpectrogramBuilder.snapshot(nearby: [littleBrownBat], deployMode: .sm5bat)
        let ultraEndangered = endangered.bands.first { $0.id == "ultra" }!.level
        let ultraAcoustic = acoustic.bands.first { $0.id == "ultra" }!.level
        XCTAssertGreaterThan(ultraEndangered, ultraAcoustic)
    }

    func testSpeciesCatalogRecordsAndPersists() {
        let suite = "swarm-catalog-test-\(ProcessInfo.processInfo.processIdentifier)"
        let ud = UserDefaults(suiteName: suite)!
        ud.removePersistentDomain(forName: suite)
        let store = SpeciesCatalogStore(defaults: ud)
        XCTAssertEqual(store.discoveredCount, 0)
        store.record(woodThrush)
        store.record(woodThrush)
        store.record(littleBrownBat)
        XCTAssertEqual(store.count(for: woodThrush), 2)
        XCTAssertEqual(store.discoveredCount, 2)
        let reloaded = SpeciesCatalogStore(defaults: ud)
        XCTAssertEqual(reloaded.count(for: woodThrush), 2)
        XCTAssertEqual(reloaded.count(for: littleBrownBat), 1)
    }

    func testProjectSpeciesCatalogHasTwelveEntries() {
        XCTAssertEqual(ProjectSpeciesCatalog.all.count, 12)
        XCTAssertTrue(ProjectSpeciesCatalog.all.allSatisfy { !$0.scientificName.isEmpty })
    }

    func testSM5HasWiderAcousticDetectThanSM5BAT() {
        let sm5 = BalanceEngine.detectionRadius(pickupRadius: 78, orbitLevel: 0, chainLevel: 0, deployMode: .sm5)
        let bat = BalanceEngine.detectionRadius(pickupRadius: 78, orbitLevel: 0, chainLevel: 0, deployMode: .sm5bat)
        XCTAssertGreaterThan(sm5, bat)
    }

    func testListenBurstExpandsDetection() {
        let base = BalanceEngine.detectionRadius(pickupRadius: 78, orbitLevel: 1, chainLevel: 0, deployMode: .sm5, listenBurstActive: false)
        let burst = BalanceEngine.detectionRadius(pickupRadius: 78, orbitLevel: 1, chainLevel: 0, deployMode: .sm5, listenBurstActive: true)
        XCTAssertGreaterThan(burst, base)
    }

    func testDeployModePersistsInGameModel() {
        let suite = "swarm-deploy-\(ProcessInfo.processInfo.processIdentifier)"
        let ud = UserDefaults(suiteName: suite)!
        ud.removePersistentDomain(forName: suite)
        UserDefaults.standard.removeObject(forKey: "swarm_deploy_mode")
        let model = GameModel(meta: MetaStore(defaults: ud), catalog: SpeciesCatalogStore(defaults: ud))
        model.setDeployMode(.sm5bat)
        XCTAssertEqual(model.deployMode, .sm5bat)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "swarm_deploy_mode"), "sm5bat")
    }
}