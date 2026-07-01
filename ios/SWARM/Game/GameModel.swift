// Bridge between the SpriteKit gameplay (GameScene) and the SwiftUI shell.
// SwiftUI renders menu / level-up / game-over overlays; the scene drives everything else.
// Mutated only on the main thread (scene update + SwiftUI actions both run on main).

import Combine
import Foundation

struct UpgradeCard: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String   // SF Symbol
    let levelText: String
}

final class GameModel: ObservableObject {
    enum Phase { case menu, playing, levelUp, dead, meta, settings, catalog, labBoard, paused, mentorship }

    @Published var phase: Phase = .menu
    @Published var choices: [UpgradeCard] = []

    // HUD (updated live by the scene)
    @Published var hp: Int = 100
    @Published var maxHp: Int = 100
    @Published var level: Int = 1
    @Published var xp: CGFloat = 0
    @Published var xpToNext: CGFloat = 5
    @Published var timeSec: Int = 0
    @Published var kills: Int = 0

    // End-of-run snapshot
    @Published var coresEarned: Int = 0
    @Published var runBanner: String?
    @Published var captionLine: String?
    @Published var nextGoalHint: String?
    @Published var deathHeadline: String = "SURVEY ENDED"
    @Published var deathSubline: String = ""
    @Published var runWasNewBest: Bool = false
    @Published var deployMode: DeployMode = .sm5
    @Published var habitatSite: HabitatSite = .canopy
    @Published var transectMode: TransectMode = .fieldDay
    @Published var deploymentId: String?
    @Published var passiveBatMode: Bool = false
    @Published var fieldOverlayHint: String?
    @Published var spectrogram: SpectrogramSnapshot?
    @Published var activeMission: SurveyMission?
    @Published var surveyReport: SurveyRunReport?
    @Published var noiseBudgetPct: Int = 100
    @Published var speciesRichness: Int = 0
    @Published var surveyScoreBest: Bool = false
    @Published var recentVouchers: [DetectionVoucher] = []
    @Published var vetSession: VetSession?

    let meta: MetaStore
    let catalog: SpeciesCatalogStore
    let labBoard: LabBoardStore
    private var settingsReturnPhase: Phase = .menu
    private var cancellables = Set<AnyCancellable>()

    var bestTime: Int { meta.bestTime }
    var bestSurveyScore: Int { meta.bestSurveyScore }
    var cores: Int { meta.cores }

    private static let deployModeKey = "swarm_deploy_mode"

    init(
        meta: MetaStore = MetaStore(),
        catalog: SpeciesCatalogStore = SpeciesCatalogStore(),
        labBoard: LabBoardStore = LabBoardStore()
    ) {
        self.meta = meta
        self.catalog = catalog
        self.labBoard = labBoard
        if let raw = UserDefaults.standard.string(forKey: Self.deployModeKey),
           let mode = DeployMode(rawValue: raw) {
            deployMode = mode
        }
        habitatSite = GameSettings.habitatSite
        transectMode = GameSettings.transectMode
        meta.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        catalog.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        labBoard.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func setDeployMode(_ mode: DeployMode) {
        deployMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: Self.deployModeKey)
    }

    func setHabitatSite(_ site: HabitatSite) {
        habitatSite = site
        GameSettings.habitatSite = site
    }

    func setTransectMode(_ mode: TransectMode) {
        transectMode = mode
        GameSettings.transectMode = mode
    }

    // Wired by the scene
    var onStart: () -> Void = {}
    var onChoose: (String) -> Void = { _ in }
    var onRestart: () -> Void = {}
    var onListenBurst: () -> Void = {}
    var onVetDecision: (String, VetStatus) -> Void = { _, _ in }

    func start() {
        if !GameSettings.mentorshipCompleted {
            phase = .mentorship
            return
        }
        beginDeployment()
    }

    func beginDeployment() {
        runBanner = nil
        captionLine = nil
        nextGoalHint = nil
        deathHeadline = "SURVEY ENDED"
        deathSubline = ""
        runWasNewBest = false
        surveyScoreBest = false
        surveyReport = nil
        spectrogram = nil
        speciesRichness = 0
        noiseBudgetPct = 100
        recentVouchers = []
        vetSession = nil
        deploymentId = nil
        passiveBatMode = false
        fieldOverlayHint = nil
        onStart()
    }

    func completeMentorship() {
        GameSettings.mentorshipCompleted = true
        beginDeployment()
    }

    func listenBurst() { onListenBurst() }

    func submitVet(_ decision: VetStatus) {
        guard let session = vetSession else { return }
        onVetDecision(session.voucherId, decision)
    }
    func openCatalog() { phase = .catalog }
    func closeCatalog() { phase = .menu }
    func openLabBoard() { phase = .labBoard }
    func closeLabBoard() { phase = .menu }
    func pick(_ id: String) { onChoose(id) }
    func restart() { onRestart() }
    func openMeta() { phase = .meta }
    func closeMeta() { phase = .menu }
    func openSettings() {
        guard phase == .menu || phase == .paused else { return }
        settingsReturnPhase = phase
        phase = .settings
    }
    func closeSettings() { phase = settingsReturnPhase }
    func pause() {
        guard phase == .playing else { return }
        phase = .paused
    }
    func resume() {
        guard phase == .paused else { return }
        phase = .playing
    }
    func buyMeta(_ id: String) {
        guard let up = MetaCatalog.all.first(where: { $0.id == id }) else { return }
        meta.buy(up)
    }
}