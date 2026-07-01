import XCTest
@testable import SWARM

final class SpectrogramCatalogTests: XCTestCase {
    func testSpectrogramMidBandDominatesPasserineSM5() {
        let snap = SpectrogramBuilder.snapshot(nearby: [.passerine, .passerine], deployMode: .sm5)
        let mid = snap.bands.first { $0.id == "mid" }!
        let ultra = snap.bands.first { $0.id == "ultra" }!
        XCTAssertGreaterThan(mid.level, ultra.level)
        XCTAssertTrue(snap.dominantLabel?.contains("Passerine") == true)
    }

    func testSpectrogramUltraBoostedOnSM5BAT() {
        let acoustic = SpectrogramBuilder.snapshot(nearby: [.passerine], deployMode: .sm5bat)
        let endangered = SpectrogramBuilder.snapshot(nearby: [.endangered], deployMode: .sm5bat)
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
        store.record(.swift)
        store.record(.swift)
        store.record(.endangered)
        XCTAssertEqual(store.count(for: .swift), 2)
        XCTAssertEqual(store.discoveredCount, 2)
        let reloaded = SpeciesCatalogStore(defaults: ud)
        XCTAssertEqual(reloaded.count(for: .swift), 2)
        XCTAssertEqual(reloaded.count(for: .endangered), 1)
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