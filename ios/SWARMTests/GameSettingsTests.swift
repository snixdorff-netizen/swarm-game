import XCTest
@testable import SWARM

final class GameSettingsTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "SWARMSettings.\(UUID().uuidString)"
        guard let suite = UserDefaults(suiteName: suiteName) else {
            XCTFail("failed to create UserDefaults suite")
            return
        }
        defaults = suite
        GameSettings.configure(defaults: suite)
    }

    override func tearDown() {
        GameSettings.configure(defaults: .standard)
        if let suiteName { defaults?.removePersistentDomain(forName: suiteName) }
        suiteName = nil
        defaults = nil
        super.tearDown()
    }

    func testDefaultsAreOnWhenUnset() {
        XCTAssertTrue(GameSettings.soundEnabled)
        XCTAssertTrue(GameSettings.hapticsEnabled)
    }

    func testPersistsFalse() {
        GameSettings.soundEnabled = false
        GameSettings.hapticsEnabled = false
        XCTAssertFalse(GameSettings.soundEnabled)
        XCTAssertFalse(GameSettings.hapticsEnabled)
    }

    func testDefaultsRestoreWhenKeysRemoved() {
        GameSettings.soundEnabled = false
        GameSettings.hapticsEnabled = false
        defaults.removeObject(forKey: GameSettings.soundKey)
        defaults.removeObject(forKey: GameSettings.hapticsKey)
        XCTAssertTrue(GameSettings.soundEnabled)
        XCTAssertTrue(GameSettings.hapticsEnabled)
    }
}