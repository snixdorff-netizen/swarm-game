// SWARM Acoustic Field — bioacoustic survey deployment (Wildlife Acoustics–inspired workflow):
// move your Song Meter rig, auto-classifiers scan hidden fauna, confirmed IDs drop recording clips,
// rank up to choose field kit modules. Habitat disturbance ends the deployment.
//
// Fauna are faint until within acoustic detection range. Flat geometry — no art assets required.

import SpriteKit

// MARK: - Entities

private final class Enemy {
    let node: SKSpriteNode
    var hp: CGFloat
    var maxHp: CGFloat
    var speed: CGFloat
    var radius: CGFloat
    var dmg: CGFloat
    var xp: CGFloat
    var kind: Int          // archetype → EnemyKind stats
    var speciesId: String
    var flash: CGFloat = 0
    var shootTimer: CGFloat = 0
    var callTimer: CGFloat = 0
    init(node: SKSpriteNode, hp: CGFloat, speed: CGFloat, radius: CGFloat, dmg: CGFloat, xp: CGFloat,
         kind: Int = 0, speciesId: String) {
        self.node = node; self.hp = hp; self.maxHp = hp; self.speed = speed
        self.radius = radius; self.dmg = dmg; self.xp = xp; self.kind = kind
        self.speciesId = speciesId
        let project = ProjectSpeciesCatalog.with(id: speciesId) ?? ProjectSpeciesCatalog.all[0]
        let profile = SpeciesCallProfiles.profile(for: ProjectSpeciesCatalog.surveySpecies(for: project))
        callTimer = CGFloat.random(in: 0.2...(profile.callInterval * 0.85))
    }

    var projectSpecies: ProjectSpecies {
        ProjectSpeciesCatalog.with(id: speciesId) ?? ProjectSpeciesCatalog.all[0]
    }
}
private final class EnemyShot {
    let node: SKSpriteNode
    var vel: CGVector
    var dmg: CGFloat
    var life: CGFloat
    init(node: SKSpriteNode, vel: CGVector, dmg: CGFloat, life: CGFloat) {
        self.node = node; self.vel = vel; self.dmg = dmg; self.life = life
    }
}
private final class Projectile {
    let node: SKSpriteNode
    var vel: CGVector
    var dmg: CGFloat
    var pierce: Int
    var life: CGFloat
    var hitSet: Set<ObjectIdentifier> = []
    init(node: SKSpriteNode, vel: CGVector, dmg: CGFloat, pierce: Int, life: CGFloat) {
        self.node = node; self.vel = vel; self.dmg = dmg; self.pierce = pierce; self.life = life
    }
}
private final class Gem {
    let node: SKSpriteNode
    var value: CGFloat
    init(node: SKSpriteNode, value: CGFloat) { self.node = node; self.value = value }
}

// MARK: - Palette
private enum C {
    static let bg = SKColor(red: 0.03, green: 0.06, blue: 0.05, alpha: 1)
    static let grid = SKColor(red: 0.08, green: 0.14, blue: 0.11, alpha: 1)
    static let player = SKColor(red: 0.35, green: 0.85, blue: 0.55, alpha: 1)
    static let bolt = SKColor(red: 0.55, green: 0.95, blue: 0.85, alpha: 1)
    static let basic = SKColor(red: 0.45, green: 0.72, blue: 0.38, alpha: 1)
    static let fast = SKColor(red: 0.72, green: 0.88, blue: 0.42, alpha: 1)
    static let tank = SKColor(red: 0.28, green: 0.55, blue: 0.42, alpha: 1)
    static let shooter = SKColor(red: 0.55, green: 0.65, blue: 0.95, alpha: 1)
    static let boss = SKColor(red: 0.85, green: 0.45, blue: 1.0, alpha: 1)
    static let gem = SKColor(red: 0.40, green: 0.92, blue: 0.68, alpha: 1)
    static let chain = SKColor(red: 0.55, green: 0.82, blue: 0.95, alpha: 1)
    static let orbit = SKColor(red: 0.40, green: 0.88, blue: 0.62, alpha: 1)
    static let clarity = SKColor(red: 0.95, green: 0.78, blue: 0.28, alpha: 1)
}

final class GameScene: SKScene {

    weak var model: GameModel?

    // Player
    private var player = SKShapeNode()
    private var pPos = CGPoint.zero
    private var moveDir = CGVector.zero          // normalized * magnitude (0…1)
    private var hp: CGFloat = 100
    private var maxHp: CGFloat = 100
    private var moveSpeed: CGFloat = 178
    private var pickupRadius: CGFloat = 78
    private var regen: CGFloat = 0
    private var aimAngle: CGFloat = 0
    private var hurtCooldown: CGFloat = 0

    // Weapons
    private var boltDmg: CGFloat = 12
    private var boltInterval: CGFloat = 0.72
    private var boltTimer: CGFloat = 0
    private var boltCount: Int = 1
    private var boltPierce: Int = 0
    private var orbitLevel: Int = 0
    private var orbitDmg: CGFloat = 10
    private var orbitAngle: CGFloat = 0
    private var orbitNodes: [SKShapeNode] = []
    private var novaLevel: Int = 0
    private var novaDmg: CGFloat = 16
    private var novaRadius: CGFloat = 110
    private var novaInterval: CGFloat = 1.6
    private var novaTimer: CGFloat = 0
    private var novaRing = SKShapeNode()
    private var chainLevel: Int = 0
    private var chainDmg: CGFloat = 14
    private var chainInterval: CGFloat = 1.4
    private var chainTimer: CGFloat = 0
    private var leechLevel: Int = 0
    private var dmgMult: CGFloat = 1
    private var xpMult: CGFloat = 1
    private var leechPerKill: CGFloat = 0
    private var hitMilestones: Set<Int> = []
    private var hitKillStreaks: Set<Int> = []
    private var speciesCallCooldown: CGFloat = 0
    private var deployMode: DeployMode = .sm5
    private var listenBurstTimer: CGFloat = 0
    private var listenCooldown: CGFloat = 0
    private var listenRecentTimer: CGFloat = 0
    private var runMission = SurveyMission.random(deployMode: .sm5)
    private var detectionVouchers: [DetectionVoucher] = []
    private var spectrogramSeed: UInt64 = 42

    // World
    private var enemies: [Enemy] = []
    private var projectiles: [Projectile] = []
    private var enemyShots: [EnemyShot] = []
    private var gems: [Gem] = []
    private var bossSpawned = false
    private var bossWarnLabel = SKLabelNode()
    private let cam = SKCameraNode()
    private var gridNode = SKNode()

    // Progression
    private var level = 1
    private var xp: CGFloat = 0
    private var xpToNext: CGFloat = 5
    private var runTime: CGFloat = 0
    private var kills = 0
    private var spawnTimer: CGFloat = 0

    // HUD
    private var hpBar = SKShapeNode()
    private var hpBarBg = SKShapeNode()
    private var xpBar = SKShapeNode()
    private var xpBarBg = SKShapeNode()
    private var timeLabel = SKLabelNode()
    private var killLabel = SKLabelNode()
    private var lvlLabel = SKLabelNode()

    // Joystick
    private var stickBase = SKShapeNode()
    private var stickKnob = SKShapeNode()
    private var stickAnchor = CGPoint.zero
    private var sticking = false

    private var lastTime: TimeInterval = 0
    private let maxEnemies = 130
    private var autopilotMovement = false   // kiting movement (SWARM_AUTOSTART / headless batch)
    private var playerInvulnerable = false // skips hp-= (SWARM_AUTOSTART only; mortal batch uses false)
    private var casualAutopilot = false    // imperfect kiting when mortal (headless / SWARM_MORTAL_AUTOSTART)
    private var spawnRng: SeededRNG?
    var testingRunProfile: BuildProfile?

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = C.bg
        scaleMode = .resizeFill
        addChild(cam); camera = cam
        buildGrid()
        buildPlayer()
        buildHUD()
        buildStick()
        buildBossWarn()
        cam.position = pPos
        setChrome(false)
        let env = ProcessInfo.processInfo.environment
        if env["SWARM_MORTAL_AUTOSTART"] != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.startRun()
                self?.autopilotMovement = true
                self?.playerInvulnerable = false
                self?.casualAutopilot = true
            }
        } else if env["SWARM_AUTOSTART"] != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.startRun()
                self?.autopilotMovement = true
                self?.playerInvulnerable = true
            }
        }
    }

    private func buildGrid() {
        gridNode.removeFromParent()
        gridNode = SKNode()
        let step: CGFloat = 80, span: CGFloat = 2600
        let path = CGMutablePath()
        var x = -span
        while x <= span { path.move(to: CGPoint(x: x, y: -span)); path.addLine(to: CGPoint(x: x, y: span)); x += step }
        var y = -span
        while y <= span { path.move(to: CGPoint(x: -span, y: y)); path.addLine(to: CGPoint(x: span, y: y)); y += step }
        let g = SKShapeNode(path: path)
        g.strokeColor = gridStrokeColor(); g.lineWidth = 1; g.zPosition = -10
        gridNode.addChild(g)
        addChild(gridNode)
    }

    private func gridStrokeColor() -> SKColor {
        let g = deployMode.sceneGrid
        return SKColor(red: g.r, green: g.g, blue: g.b, alpha: 1)
    }

    private func applyDeployPalette() {
        let bg = deployMode.sceneBackground
        backgroundColor = SKColor(red: bg.r, green: bg.g, blue: bg.b, alpha: 1)
        buildGrid()
    }

    private func buildPlayer() {
        let r: CGFloat = 13
        player = SKShapeNode(rectOf: CGSize(width: r * 2.4, height: r * 1.7), cornerRadius: 4)
        player.fillColor = C.player
        player.strokeColor = .white
        player.lineWidth = 1.5
        player.glowWidth = 3
        player.zPosition = 5
        addChild(player)
        let mic = SKShapeNode(circleOfRadius: 3.5)
        mic.fillColor = .white
        mic.strokeColor = .clear
        mic.position = CGPoint(x: 0, y: r * 0.35)
        mic.zPosition = 1
        player.addChild(mic)
        novaRing = SKShapeNode(circleOfRadius: novaRadius)
        novaRing.strokeColor = C.orbit.withAlphaComponent(0.0)
        novaRing.lineWidth = 2; novaRing.zPosition = 3
        player.addChild(novaRing)
    }

    private func hudColor() -> SKColor { SKColor(white: 1, alpha: 0.9) }
    private func buildHUD() {
        let w = size.width, h = size.height
        let left = -w/2, top = h/2
        func bar(_ color: SKColor) -> SKShapeNode {
            let n = SKShapeNode(rectOf: CGSize(width: 1, height: 1), cornerRadius: 3)
            n.fillColor = color; n.strokeColor = .clear; return n
        }
        hpBarBg = bar(SKColor(white: 1, alpha: 0.12)); hpBar = bar(C.clarity)
        xpBarBg = bar(SKColor(white: 1, alpha: 0.12)); xpBar = bar(C.player)
        [hpBarBg, hpBar, xpBarBg, xpBar].forEach { $0.zPosition = 50; cam.addChild($0) }
        timeLabel = label(34, weight: .heavy); killLabel = label(14, weight: .medium); lvlLabel = label(14, weight: .medium)
        timeLabel.position = CGPoint(x: 0, y: top - 56)
        killLabel.position = CGPoint(x: 0, y: top - 78); killLabel.horizontalAlignmentMode = .center
        lvlLabel.position = CGPoint(x: left + 16, y: top - 30); lvlLabel.horizontalAlignmentMode = .left
        [timeLabel, killLabel, lvlLabel].forEach { cam.addChild($0) }
        layoutHUD()
    }
    private func label(_ s: CGFloat, weight: UIFont.Weight) -> SKLabelNode {
        let n = SKLabelNode(text: "")
        n.fontName = weight == .heavy ? "AvenirNextCondensed-Heavy" : "AvenirNext-Medium"
        n.fontSize = s; n.fontColor = hudColor(); n.zPosition = 50
        n.horizontalAlignmentMode = .center; n.verticalAlignmentMode = .center
        return n
    }
    private func layoutHUD() {
        let w = size.width, h = size.height, top = h/2
        let barW = w - 32
        func place(_ bg: SKShapeNode, _ fg: SKShapeNode, y: CGFloat, frac: CGFloat, height: CGFloat) {
            bg.xScale = barW; bg.yScale = height; bg.position = CGPoint(x: 0, y: y)
            let fw = max(0.001, barW * frac)
            fg.xScale = fw; fg.yScale = height; fg.position = CGPoint(x: -barW/2 + fw/2, y: y)
        }
        place(hpBarBg, hpBar, y: top - 100, frac: maxHp > 0 ? hp/maxHp : 0, height: 10)
        place(xpBarBg, xpBar, y: top - 114, frac: xpToNext > 0 ? xp/xpToNext : 0, height: 5)
    }

    private func buildBossWarn() {
        bossWarnLabel = label(28, weight: .heavy)
        bossWarnLabel.fontColor = C.boss
        bossWarnLabel.isHidden = true
        bossWarnLabel.zPosition = 55
        cam.addChild(bossWarnLabel)
    }

    private func buildStick() {
        stickBase = SKShapeNode(circleOfRadius: 52)
        stickBase.strokeColor = SKColor(white: 1, alpha: 0.18); stickBase.lineWidth = 3; stickBase.fillColor = SKColor(white: 1, alpha: 0.04)
        stickKnob = SKShapeNode(circleOfRadius: 24)
        stickKnob.fillColor = SKColor(white: 1, alpha: 0.22); stickKnob.strokeColor = .clear
        stickBase.zPosition = 60; stickKnob.zPosition = 61
        stickBase.isHidden = true; stickKnob.isHidden = true
        cam.addChild(stickBase); cam.addChild(stickKnob)
    }

    // MARK: - Run lifecycle

    func startRun() {
        enemies.forEach { $0.node.removeFromParent() }; enemies.removeAll()
        projectiles.forEach { $0.node.removeFromParent() }; projectiles.removeAll()
        enemyShots.forEach { $0.node.removeFromParent() }; enemyShots.removeAll()
        gems.forEach { $0.node.removeFromParent() }; gems.removeAll()
        orbitNodes.forEach { $0.removeFromParent() }; orbitNodes.removeAll()
        bossSpawned = false; bossWarnLabel.isHidden = true
        deployMode = model?.deployMode ?? .sm5
        listenBurstTimer = 0
        listenCooldown = 0
        listenRecentTimer = 0
        detectionVouchers.removeAll()
        spectrogramSeed = UInt64.random(in: 1000...99999)
        let habitat = model?.habitatSite ?? GameSettings.habitatSite
        runMission = SurveyMission.random(deployMode: deployMode, habitat: habitat, seed: spectrogramSeed)
        model?.activeMission = runMission
        model?.spectrogram = nil
        model?.surveyReport = nil
        applyDeployPalette()
        let meta = model?.meta
        dmgMult = meta?.damageMult ?? 1
        hp = 100 + (meta?.bonusHp ?? 0); maxHp = hp
        moveSpeed = 178 * (meta?.speedMult ?? 1)
        pickupRadius = 78 + (meta?.bonusMagnet ?? 0); regen = 0
        boltDmg = 12; boltInterval = 0.72; boltTimer = 0; boltCount = 1; boltPierce = 0
        orbitLevel = 0; orbitDmg = 10; novaLevel = 0; novaDmg = 16; novaRadius = 110; novaInterval = 1.6
        chainLevel = 0; chainDmg = 14; chainInterval = 1.4; chainTimer = 0
        leechLevel = 0
        xpMult = meta?.xpMult ?? 1
        leechPerKill = meta?.leechPerKill ?? 0
        hitMilestones.removeAll()
        hitKillStreaks.removeAll()
        novaRing.path = CGPath(ellipseIn: CGRect(x: -novaRadius, y: -novaRadius, width: novaRadius*2, height: novaRadius*2), transform: nil)
        level = 1; xp = 0; xpToNext = BalanceEngine.initialXpToNext(); runTime = 0; kills = 0; spawnTimer = 0
        pPos = .zero; player.position = .zero; player.zRotation = 0
        cam.position = .zero
        publishHUD(); layoutHUD()
        setChrome(true)
        for _ in 0..<4 { spawnOne() }
        model?.phase = .playing
    }

    private func setChrome(_ v: Bool) {
        let nodes: [SKNode] = [player, hpBar, hpBarBg, xpBar, xpBarBg, timeLabel, killLabel, lvlLabel]
        nodes.forEach { $0.isHidden = !v }
    }

    func applyUpgrade(_ id: String) {
        switch id {
        case "bolt_dmg": boltDmg += 7
        case "bolt_rate": boltInterval = max(0.18, boltInterval * 0.82)
        case "bolt_count": boltCount += 1
        case "bolt_pierce": boltPierce += 1
        case "orbit": if orbitLevel == 0 { orbitLevel = 1 } else { orbitLevel += 1 }; rebuildOrbit()
        case "orbit_dmg": orbitDmg += 8
        case "nova": if novaLevel == 0 { novaLevel = 1 } else { novaLevel += 1 }; novaInterval = max(0.6, novaInterval * 0.85)
        case "nova_radius": novaRadius += 34; novaRing.path = CGPath(ellipseIn: CGRect(x: -novaRadius, y: -novaRadius, width: novaRadius*2, height: novaRadius*2), transform: nil)
        case "max_hp": maxHp += 25; hp += 25
        case "move": moveSpeed += 22
        case "pickup": pickupRadius += 36
        case "regen": regen += 1.4
        case "chain": if chainLevel == 0 { chainLevel = 1 } else { chainLevel += 1 }; chainInterval = max(0.5, chainInterval * 0.88)
        case "chain_dmg": chainDmg += 9
        case "leech": if leechLevel == 0 { leechLevel = 1 } else { leechLevel += 1 }
        default: break
        }
        model?.phase = .playing
    }

    func restartToMenu() { setChrome(false); model?.phase = .menu }

    private func rebuildOrbit() {
        orbitNodes.forEach { $0.removeFromParent() }; orbitNodes.removeAll()
        let n = orbitLevel + 1
        for _ in 0..<n {
            let b = SKShapeNode(rectOf: CGSize(width: 16, height: 16), cornerRadius: 3)
            b.fillColor = C.orbit; b.strokeColor = .white; b.lineWidth = 1; b.glowWidth = 3; b.zPosition = 4
            addChild(b); orbitNodes.append(b)
        }
    }

    // MARK: - Main loop

    override func update(_ currentTime: TimeInterval) {
        let dt = min(0.033, lastTime == 0 ? 0 : CGFloat(currentTime - lastTime))
        lastTime = currentTime
        guard model?.phase == .playing, dt > 0 else { return }

        runTime += dt
        if listenBurstTimer > 0 {
            listenBurstTimer -= dt
            if listenBurstTimer <= 0 { model?.spectrogram = nil }
        }
        if listenCooldown > 0 { listenCooldown -= dt }
        if listenRecentTimer > 0 { listenRecentTimer -= dt }
        if autopilotMovement {
            let casual = casualAutopilot && !playerInvulnerable
            let fleeR = casual ? BalanceEngine.casualAutopilotFleeRadius : 220
            let fleeStr = casual ? BalanceEngine.casualAutopilotEfficiency : 0.88
            var fleeX: CGFloat = 0, fleeY: CGFloat = 0, nearby = 0
            for e in enemies {
                let dx = pPos.x - e.node.position.x, dy = pPos.y - e.node.position.y
                let d2 = dx*dx + dy*dy
                if d2 < fleeR * fleeR {
                    let d = max(1, d2.squareRoot())
                    fleeX += dx / d
                    fleeY += dy / d
                    nearby += 1
                }
            }
            if nearby > 0 {
                let d = max(1, (fleeX*fleeX + fleeY*fleeY).squareRoot())
                moveDir = CGVector(dx: fleeX/d * fleeStr + (-fleeY/d) * 0.28, dy: fleeY/d * fleeStr + (fleeX/d) * 0.28)
            } else if let e = nearestEnemy() {
                let dx = pPos.x - e.node.position.x, dy = pPos.y - e.node.position.y
                let d = max(1, (dx*dx + dy*dy).squareRoot())
                moveDir = CGVector(dx: dx/d * fleeStr, dy: dy/d * fleeStr)
            } else {
                moveDir = CGVector(dx: cos(runTime * 1.1), dy: sin(runTime * 1.1))
            }
            if casual {
                let wobble = sin(runTime * 5.1) * 0.34 * (1 - BalanceEngine.casualAutopilotEfficiency)
                moveDir = CGVector(dx: moveDir.dx + wobble, dy: moveDir.dy - wobble * 0.65)
                let mag = max(0.38, (moveDir.dx*moveDir.dx + moveDir.dy*moveDir.dy).squareRoot())
                moveDir = CGVector(dx: moveDir.dx / mag, dy: moveDir.dy / mag)
            }
        }
        if regen > 0 && hp < maxHp { hp = min(maxHp, hp + regen * dt) }
        if hurtCooldown > 0 { hurtCooldown -= dt }

        // Move player
        let moveScale: CGFloat = (casualAutopilot && !playerInvulnerable) ? BalanceEngine.casualAutopilotEfficiency : 1
        pPos.x += moveDir.dx * moveSpeed * dt * moveScale
        pPos.y += moveDir.dy * moveSpeed * dt * moveScale
        player.position = pPos
        cam.position = pPos

        updateAim()
        spawn(dt)
        maybeBoss()
        updateEnemies(dt)
        updateSpeciesCalls(dt)
        fireWeapons(dt)
        updateProjectiles(dt)
        updateEnemyShots(dt)
        updateOrbit(dt)
        updateGems(dt)

        if model?.phase == .levelUp {
            publishHUD()
            return
        }
        if hp <= 0 { endDeployment(aborted: true) ; return }
        publishHUD()
        let sec = Int(runTime)
        if sec != model?.timeSec {
            model?.timeSec = sec
            checkMilestones(sec)
            if sec >= runMission.transectDurationSec {
                endDeployment(aborted: false)
                return
            }
        }
    }

    private func checkMilestones(_ sec: Int) {
        if sec == BalanceEngine.bossTeaseSeconds, !hitMilestones.contains(sec) {
            hitMilestones.insert(sec)
            showRunBanner(BalanceEngine.bossTeaseBanner(), pulse: true)
        }
        guard BalanceEngine.milestoneSeconds.contains(sec), !hitMilestones.contains(sec) else { return }
        hitMilestones.insert(sec)
        guard let banner = BalanceEngine.milestoneBanner(for: sec) else { return }
        showRunBanner(banner, pulse: true)
    }

    private func checkKillStreak(_ totalKills: Int) {
        // Boss anticipation (75–90s) outranks streak pop-ups — keeps casual players oriented.
        if runTime >= CGFloat(BalanceEngine.bossTeaseSeconds),
           runTime < BalanceEngine.bossSpawnSeconds { return }
        guard BalanceEngine.killStreakThresholds.contains(totalKills),
              !hitKillStreaks.contains(totalKills),
              let banner = BalanceEngine.killStreakBanner(for: totalKills) else { return }
        hitKillStreaks.insert(totalKills)
        showRunBanner(banner, pulse: true)
        SfxPlayer.shared.levelUp()
        Haptics.shared.kill()
    }

    private func showRunBanner(_ banner: String, pulse: Bool = false, duration: TimeInterval = 2.8) {
        model?.runBanner = banner
        if pulse { pulseMilestone(banner) }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            if self?.model?.runBanner == banner { self?.model?.runBanner = nil }
        }
    }

    private func showDetectionBanner(_ banner: String, pulse: Bool = false, duration: TimeInterval = 1.2) {
        if let current = model?.runBanner, isPriorityRunBanner(current) { return }
        showRunBanner(banner, pulse: pulse, duration: duration)
    }

    private func isPriorityRunBanner(_ banner: String) -> Bool {
        if banner == BalanceEngine.bossTeaseBanner() { return true }
        return BalanceEngine.milestoneSeconds.contains { BalanceEngine.milestoneBanner(for: $0) == banner }
    }

    private func publishCaption(_ text: String) {
        guard GameSettings.captionsEnabled else { return }
        model?.captionLine = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
            if self?.model?.captionLine == text { self?.model?.captionLine = nil }
        }
    }

    private func pulseMilestone(_ text: String) {
        let n = label(22, weight: .heavy)
        n.text = text
        n.fontColor = C.gem
        n.position = CGPoint(x: 0, y: size.height * 0.08)
        n.zPosition = 55
        cam.addChild(n)
        n.run(.sequence([.group([.scale(to: 1.08, duration: 0.2), .fadeIn(withDuration: 0.1)]),
                         .wait(forDuration: 1.6),
                         .fadeOut(withDuration: 0.4), .removeFromParent()]))
    }

    private func nearestEnemy() -> Enemy? {
        var best: Enemy?; var bd: CGFloat = .greatestFiniteMagnitude
        for e in enemies {
            let dx = e.node.position.x - pPos.x, dy = e.node.position.y - pPos.y
            let d = dx*dx + dy*dy
            if d < bd { bd = d; best = e }
        }
        return best
    }
    private func updateAim() {
        if let e = nearestEnemy() {
            aimAngle = atan2(e.node.position.y - pPos.y, e.node.position.x - pPos.x)
            let cur = player.zRotation
            var diff = aimAngle - cur
            while diff > .pi { diff -= 2 * .pi }; while diff < -.pi { diff += 2 * .pi }
            player.zRotation = cur + diff * 0.25
        }
    }

    // MARK: - Spawning & difficulty

    private func spawn(_ dt: CGFloat) {
        spawnTimer -= dt
        let interval = BalanceEngine.spawnInterval(runTime: runTime)
        if spawnTimer <= 0 && enemies.count < BalanceEngine.maxEnemies {
            spawnTimer = interval
            let batch = BalanceEngine.spawnBatchSize(runTime: runTime)
            for _ in 0..<batch { spawnOne() }
        }
    }
    private func spawnUnit() -> CGFloat {
        if var rng = spawnRng {
            let v = CGFloat(rng.nextUnit())
            spawnRng = rng
            return v
        }
        return CGFloat.random(in: 0..<1)
    }

    private func spawnOne() {
        let ang = spawnUnit() * (2 * .pi)
        let dist = max(size.width, size.height) * 0.56
        let pos = CGPoint(x: pPos.x + cos(ang) * dist, y: pPos.y + sin(ang) * dist)
        let roll = spawnUnit()
        let kind = BalanceEngine.enemyKind(runTime: runTime, roll: roll, deployMode: deployMode)
        let stats = BalanceEngine.enemyStats(kind: kind, runTime: runTime)
        var color = C.basic, sz: CGFloat = 22
        switch kind {
        case .fast: color = C.fast; sz = 16
        case .tank: color = C.tank; sz = 36
        case .shooter: color = C.shooter; sz = 18
        case .boss: color = C.boss; sz = 64
        default: break
        }
        let node = SKSpriteNode(color: color, size: CGSize(width: sz, height: sz))
        node.position = pos; node.zRotation = kind == .shooter ? 0 : .pi/4; node.zPosition = kind == .boss ? 6 : 2
        node.alpha = 0.12
        addChild(node)
        let ring = SKShapeNode(circleOfRadius: stats.radius + 10)
        ring.strokeColor = color.withAlphaComponent(0.45)
        ring.lineWidth = 1.2
        ring.fillColor = .clear
        ring.zPosition = 1
        node.addChild(ring)
        ring.run(.repeatForever(.sequence([
            .group([.scale(to: 1.22, duration: 0.9), .fadeAlpha(to: 0.25, duration: 0.9)]),
            .group([.scale(to: 1.0, duration: 0.9), .fadeAlpha(to: 0.55, duration: 0.9)])
        ])))
        let speciesRoll = spawnUnit()
        let archetype = BalanceEngine.speciesArchetype(for: kind, roll: speciesRoll, deployMode: deployMode)
        let habitat = model?.habitatSite ?? GameSettings.habitatSite
        let species = HabitatSite.pickSpecies(archetype: archetype, roll: speciesRoll, habitat: habitat)
        enemies.append(Enemy(node: node, hp: stats.hp, speed: stats.speed, radius: stats.radius,
                             dmg: stats.damage, xp: stats.xp, kind: kind.rawValue, speciesId: species.id))
    }

    private func maybeBoss() {
        guard !bossSpawned, runTime >= BalanceEngine.bossSpawnSeconds else { return }
        bossSpawned = true
        spawnBoss()
    }

    private func spawnBoss() {
        let batCall = ProjectSpeciesCatalog.surveySpecies(for:
            deployMode == .sm5bat ? ProjectSpeciesCatalog.with(id: "hoary_bat")! : ProjectSpeciesCatalog.with(id: "little_brown_bat")!
        )
        SpeciesCallSynth.shared.play(species: batCall, pan: 0, volume: 0.55)
        SfxPlayer.shared.boss(); Haptics.shared.boss()
        let rareBanner = "⚠ ENDANGERED ULTRASONIC"
        model?.runBanner = rareBanner
        bossWarnLabel.text = "⚠ SM5BAT-CLASS SIGNAL"
        bossWarnLabel.isHidden = false
        bossWarnLabel.run(.sequence([.wait(forDuration: 2.2), .fadeOut(withDuration: 0.4), .run { [weak self] in
            self?.bossWarnLabel.isHidden = true; self?.bossWarnLabel.alpha = 1
            if self?.model?.runBanner == rareBanner { self?.model?.runBanner = nil }
        }]))
        let ang = spawnUnit() * (2 * .pi)
        let dist = max(size.width, size.height) * 0.5
        let pos = CGPoint(x: pPos.x + cos(ang) * dist, y: pPos.y + sin(ang) * dist)
        let stats = BalanceEngine.enemyStats(kind: .boss, runTime: runTime)
        let node = SKSpriteNode(color: C.boss, size: CGSize(width: 64, height: 64))
        node.position = pos; node.zRotation = .pi/4; node.zPosition = 6
        addChild(node)
        let bat = deployMode == .sm5bat
            ? ProjectSpeciesCatalog.with(id: "hoary_bat")!
            : ProjectSpeciesCatalog.with(id: "little_brown_bat")!
        enemies.append(Enemy(node: node, hp: stats.hp, speed: stats.speed, radius: stats.radius,
                             dmg: stats.damage, xp: stats.xp, kind: EnemyKind.boss.rawValue, speciesId: bat.id))
    }

    private func updateEnemies(_ dt: CGFloat) {
        let chaseMult = 1 + min(0.85, runTime * 0.01)
        let detectR = BalanceEngine.detectionRadius(
            pickupRadius: pickupRadius, orbitLevel: orbitLevel, chainLevel: chainLevel,
            deployMode: deployMode, listenBurstActive: listenBurstTimer > 0
        )
        for e in enemies {
            let dx = pPos.x - e.node.position.x, dy = pPos.y - e.node.position.y
            let d = max(1, (dx*dx + dy*dy).squareRoot())
            var visibility = min(1, max(0.1, 1.15 - d / detectR))
            if e.projectSpecies.callBand == .ultrasonic {
                visibility = min(1, visibility * deployMode.ultrasonicVisibilityBoost)
            }
            e.node.alpha = e.kind == EnemyKind.boss.rawValue ? max(0.35, visibility) : visibility
            if e.kind == 3 {
                let keep = e.radius + 140
                if d < keep { e.node.position.x -= dx/d * e.speed * dt; e.node.position.y -= dy/d * e.speed * dt }
                else { e.node.position.x += dx/d * e.speed * 0.6 * dt; e.node.position.y += dy/d * e.speed * 0.6 * dt }
                e.shootTimer -= dt
                if e.shootTimer <= 0 {
                    e.shootTimer = 1.35
                    fireEnemyShot(from: e.node.position, dmg: e.dmg * 0.75)
                }
            } else if e.kind == 9 {
                e.node.position.x += dx/d * e.speed * dt
                e.node.position.y += dy/d * e.speed * dt
                e.shootTimer -= dt
                if e.shootTimer <= 0 {
                    e.shootTimer = 0.9
                    for i in -1...1 { fireEnemyShot(from: e.node.position, dmg: e.dmg * 0.35, spread: CGFloat(i) * 0.22) }
                }
            } else {
                e.node.position.x += dx/d * e.speed * chaseMult * dt
                e.node.position.y += dy/d * e.speed * chaseMult * dt
            }
            if e.flash > 0 { e.flash -= dt; if e.flash <= 0 { e.node.colorBlendFactor = 0 } }
            if d < e.radius + 13 && hurtCooldown <= 0 {
                if !playerInvulnerable {
                    var pack = 0
                    for other in enemies {
                        let odx = pPos.x - other.node.position.x, ody = pPos.y - other.node.position.y
                        if odx*odx + ody*ody < 52 * 52 { pack += 1 }
                    }
                    let packMult = 1 + CGFloat(min(pack, 8)) * 0.04
                    let timeDmgScale: CGFloat = {
                        if runTime < 26 { return 0.76 }
                        if runTime > 100 { return 1.55 }
                        if runTime > 88 { return 1.38 }
                        return 1.0
                    }()
                    hp -= e.dmg * BalanceEngine.difficultyScale(runTime: runTime) * packMult * timeDmgScale
                    flashHurt()
                }
                hurtCooldown = BalanceEngine.contactHurtCooldown
            }
        }
    }

    private func updateSpeciesCalls(_ dt: CGFloat) {
        guard model?.phase == .playing else { return }
        speciesCallCooldown = max(0, speciesCallCooldown - dt)
        let listenActive = listenBurstTimer > 0
        let detectR = BalanceEngine.detectionRadius(
            pickupRadius: pickupRadius, orbitLevel: orbitLevel, chainLevel: chainLevel,
            deployMode: deployMode, listenBurstActive: listenActive
        )
        let hearR = BalanceEngine.hearRadius(detectionRadius: detectR)

        for e in enemies {
            e.callTimer -= dt
            guard e.callTimer <= 0 else { continue }

            let dx = e.node.position.x - pPos.x
            let dy = e.node.position.y - pPos.y
            let d = (dx * dx + dy * dy).squareRoot()
            guard d <= hearR else {
                e.callTimer = 0.35
                continue
            }
            guard speciesCallCooldown <= 0 else { continue }

            let project = e.projectSpecies
            let legacy = ProjectSpeciesCatalog.surveySpecies(for: project)
            let profile = SpeciesCallProfiles.profile(for: legacy)
            let pan = Float(max(-1, min(1, dx / max(d, 1))))
            let proximity = max(0.15, 1 - d / hearR)
            let vol = Float(proximity) * (project.callBand == .ultrasonic ? 0.62 : 0.48)
            SpeciesCallSynth.shared.play(species: legacy, pan: pan, volume: vol)

            let jitter = CGFloat.random(in: 0.75...1.25)
            e.callTimer = profile.callInterval * jitter * deployMode.callIntervalScale
            speciesCallCooldown = (project.callBand == .ultrasonic ? 0.08 : 0.14) * deployMode.callIntervalScale
        }
    }

    private func fireEnemyShot(from pos: CGPoint, dmg: CGFloat, spread: CGFloat = 0) {
        let dx = pPos.x - pos.x, dy = pPos.y - pos.y
        let ang = atan2(dy, dx) + spread
        let speed: CGFloat = 210
        let node = SKSpriteNode(color: C.shooter, size: CGSize(width: 10, height: 10))
        node.position = pos; node.zPosition = 3
        addChild(node)
        enemyShots.append(EnemyShot(node: node, vel: CGVector(dx: cos(ang)*speed, dy: sin(ang)*speed), dmg: dmg, life: 2.8))
    }

    private func updateEnemyShots(_ dt: CGFloat) {
        for s in enemyShots {
            s.node.position.x += s.vel.dx * dt
            s.node.position.y += s.vel.dy * dt
            s.life -= dt
            let dx = pPos.x - s.node.position.x, dy = pPos.y - s.node.position.y
            if dx*dx + dy*dy < 18*18 && hurtCooldown <= 0 {
                if !playerInvulnerable {
                    let shotScale: CGFloat = runTime > 55 ? 1.12 : 1.0
                    hp -= s.dmg * shotScale
                    flashHurt()
                }
                hurtCooldown = BalanceEngine.shotHurtCooldown
                s.life = 0
            }
        }
        enemyShots.removeAll { s in
            if s.life <= 0 { s.node.removeFromParent(); return true }
            return false
        }
    }

    // MARK: - Weapons

    private func fireWeapons(_ dt: CGFloat) {
        boltTimer -= dt
        if boltTimer <= 0, let _ = nearestEnemy() {
            boltTimer = boltInterval
            let spread: CGFloat = 0.18
            for i in 0..<boltCount {
                let off = (CGFloat(i) - CGFloat(boltCount - 1)/2) * spread
                fireBolt(angle: aimAngle + off)
            }
        }
        if novaLevel > 0 {
            novaTimer -= dt
            if novaTimer <= 0 {
                novaTimer = novaInterval
                novaPulse()
            }
        }
        if chainLevel > 0 {
            chainTimer -= dt
            if chainTimer <= 0, let first = nearestEnemy() {
                chainTimer = chainInterval
                chainLightning(from: first)
            }
        }
    }
    private func fireBolt(angle: CGFloat) {
        let speed: CGFloat = 460
        let node = SKSpriteNode(color: C.bolt, size: CGSize(width: 14, height: 5))
        node.position = pPos; node.zRotation = angle; node.zPosition = 4
        addChild(node)
        projectiles.append(Projectile(node: node, vel: CGVector(dx: cos(angle)*speed, dy: sin(angle)*speed), dmg: boltDmg * dmgMult, pierce: boltPierce, life: 1.4))
    }
    private func chainLightning(from start: Enemy) {
        SfxPlayer.shared.chain()
        var hit: [Enemy] = [start]
        var pool = enemies.filter { $0 !== start }
        let jumps = 2 + chainLevel
        var last = start.node.position
        for _ in 0..<jumps {
            guard let next = pool.min(by: {
                dist($0.node.position, last) < dist($1.node.position, last)
            }) else { break }
            let p2 = next.node.position
            drawChain(from: last, to: p2)
            damage(next, chainDmg * dmgMult)
            hit.append(next)
            pool.removeAll { $0 === next }
            last = p2
        }
        damage(start, chainDmg * dmgMult * 0.6)
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x, dy = a.y - b.y
        return dx*dx + dy*dy
    }

    private func drawChain(from a: CGPoint, to b: CGPoint) {
        let path = CGMutablePath()
        path.move(to: a); path.addLine(to: b)
        let line = SKShapeNode(path: path)
        line.strokeColor = C.chain; line.lineWidth = 2; line.glowWidth = 4; line.zPosition = 7
        addChild(line)
        line.run(.sequence([.fadeOut(withDuration: 0.12), .removeFromParent()]))
    }

    private func novaPulse() {
        SfxPlayer.shared.nova()
        let r = novaRadius
        let ring = SKShapeNode(circleOfRadius: 8)
        ring.position = pPos; ring.strokeColor = C.orbit; ring.lineWidth = 3; ring.fillColor = .clear; ring.zPosition = 3; ring.glowWidth = 2
        addChild(ring)
        ring.run(.sequence([.group([.scale(to: r/8, duration: 0.32), .fadeOut(withDuration: 0.32)]), .removeFromParent()]))
        let dmg = novaDmg * CGFloat(novaLevel) * dmgMult
        for e in enemies {
            let dx = e.node.position.x - pPos.x, dy = e.node.position.y - pPos.y
            if dx*dx + dy*dy < r*r { damage(e, dmg) }
        }
    }

    private func updateProjectiles(_ dt: CGFloat) {
        for p in projectiles {
            p.node.position.x += p.vel.dx * dt
            p.node.position.y += p.vel.dy * dt
            p.life -= dt
            for e in enemies {
                let oid = ObjectIdentifier(e)
                if p.hitSet.contains(oid) { continue }
                let dx = e.node.position.x - p.node.position.x, dy = e.node.position.y - p.node.position.y
                if dx*dx + dy*dy < (e.radius + 7) * (e.radius + 7) {
                    damage(e, p.dmg); p.hitSet.insert(oid)
                    if p.pierce <= 0 { p.life = 0; break } else { p.pierce -= 1 }
                }
            }
        }
        projectiles.removeAll { p in
            if p.life <= 0 { p.node.removeFromParent(); return true }
            return false
        }
    }

    private func updateOrbit(_ dt: CGFloat) {
        guard orbitLevel > 0, !orbitNodes.isEmpty else { return }
        orbitAngle += dt * 3.0
        let radius: CGFloat = 64
        let dmg = orbitDmg
        for (i, b) in orbitNodes.enumerated() {
            let a = orbitAngle + CGFloat(i) * (2 * .pi / CGFloat(orbitNodes.count))
            let bx = pPos.x + cos(a) * radius, by = pPos.y + sin(a) * radius
            b.position = CGPoint(x: bx, y: by); b.zRotation = a
            for e in enemies {
                let dx = e.node.position.x - bx, dy = e.node.position.y - by
                if dx*dx + dy*dy < (e.radius + 10) * (e.radius + 10) {
                    damage(e, dmg * dmgMult * dt * 6, showFloater: false)
                }
            }
        }
    }

    // MARK: - Damage / death / xp

    private func damage(_ e: Enemy, _ amount: CGFloat, showFloater: Bool = true) {
        let dealt = max(1, Int(amount))
        e.hp -= amount
        e.flash = 0.07
        e.node.color = .white; e.node.colorBlendFactor = 0.9
        if showFloater { showDamage(at: e.node.position, amount: dealt, boss: e.kind == 9) }
        if Int(runTime * 60) % 3 == 0 { SfxPlayer.shared.hit() }
        if e.hp <= 0 { kill(e) }
    }

    private func showDamage(at p: CGPoint, amount: Int, boss: Bool = false) {
        let n = SKLabelNode(text: "\(amount)")
        n.fontName = "AvenirNextCondensed-Heavy"
        n.fontSize = boss ? 18 : 13
        n.fontColor = boss ? C.boss : .white
        n.position = CGPoint(x: p.x + CGFloat.random(in: -6...6), y: p.y + 10)
        n.zPosition = 20
        addChild(n)
        n.run(.sequence([
            .group([.moveBy(x: 0, y: 28, duration: 0.45), .fadeOut(withDuration: 0.45)]),
            .removeFromParent()
        ]))
    }
    private func kill(_ e: Enemy) {
        let project = e.projectSpecies
        let legacy = ProjectSpeciesCatalog.surveySpecies(for: project)
        let validated = e.kind != 3 || listenRecentTimer > 0
        let confidence = SurveyScoreEngine.confidence(for: e.kind, listenBurstRecently: listenRecentTimer > 0)
        e.node.removeFromParent()
        if let idx = enemies.firstIndex(where: { $0 === e }) { enemies.remove(at: idx) }
        kills += 1; model?.kills = kills
        if e.kind == 3 && !validated {
            hp = max(0, hp - BalanceEngine.falsePositiveNoisePenalty)
            flashHurt()
            showDetectionBanner("False positive — noise budget −\(Int(BalanceEngine.falsePositiveNoisePenalty))", pulse: true, duration: 1.4)
        }
        let voucher = DetectionVoucher(
            id: "v-\(kills)-\(Int(runTime))",
            speciesId: project.id,
            commonName: project.commonName,
            scientificName: project.scientificName,
            confidence: confidence,
            timeSec: Int(runTime),
            validated: validated
        )
        detectionVouchers.append(voucher)
        model?.speciesRichness = Set(detectionVouchers.map(\.speciesId)).count
        model?.recentVouchers = Array(detectionVouchers.suffix(3))
        if !(e.kind == 3 && !validated) {
            showDetectionBanner(
                validated ? "Detection: \(project.commonName)" : "Tentative: \(project.commonName)",
                pulse: false, duration: 1.2
            )
        }
        checkKillStreak(kills)
        let leech = CGFloat(leechLevel) * 5 + leechPerKill * 1.25
        if leech > 0 { hp = min(maxHp, hp + leech) }
        model?.catalog.record(project, deployMode: deployMode)
        model?.labBoard.noteLocalDetection(species: project, habitat: model?.habitatSite ?? GameSettings.habitatSite, deployMode: deployMode)
        publishCaption(validated ? "Detection: \(project.commonName)" : "Tentative: \(project.commonName)")
        SpeciesCallSynth.shared.playConfirm(species: legacy)
        SfxPlayer.shared.kill(); Haptics.shared.kill()
        burst(at: e.node.position, color: e.node.color)
        dropGem(at: e.node.position, value: e.xp)
    }
    private func burst(at p: CGPoint, color: SKColor) {
        for _ in 0..<7 {
            let s = SKSpriteNode(color: color, size: CGSize(width: 5, height: 5))
            s.position = p; s.zPosition = 3; addChild(s)
            let a = CGFloat.random(in: 0..<(2 * .pi)); let dpx = CGFloat.random(in: 18...46)
            s.run(.sequence([.group([.move(by: CGVector(dx: cos(a)*dpx, dy: sin(a)*dpx), duration: 0.3), .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
        }
    }
    private func dropGem(at p: CGPoint, value: CGFloat) {
        let node = SKSpriteNode(color: C.gem, size: CGSize(width: 9, height: 9))
        node.position = p; node.zRotation = .pi/4; node.zPosition = 1; node.glowFor()
        addChild(node)
        gems.append(Gem(node: node, value: value))
    }
    private func updateGems(_ dt: CGFloat) {
        for g in gems {
            guard model?.phase == .playing else { break }
            let dx = pPos.x - g.node.position.x, dy = pPos.y - g.node.position.y
            let d = (dx*dx + dy*dy).squareRoot()
            if d < pickupRadius {
                let pull: CGFloat = 320
                g.node.position.x += dx/max(1,d) * pull * dt
                g.node.position.y += dy/max(1,d) * pull * dt
            }
            if d < 16 { gainXP(g.value); SfxPlayer.shared.pickup(); g.node.removeFromParent() }
        }
        gems.removeAll { $0.node.parent == nil }
    }
    private func gainXP(_ v: CGFloat) {
        guard model?.phase == .playing else { return }
        xp += v * xpMult
        if xp >= xpToNext {
            xp -= xpToNext; level += 1
            xpToNext = BalanceEngine.xpThresholdAfterLevel(current: xpToNext)
            model?.level = level
            levelUp()
        }
    }

    private func flashHurt() {
        SfxPlayer.shared.hurt(); Haptics.shared.hurt()
        let f = SKSpriteNode(color: SKColor(red: 1, green: 0.1, blue: 0.2, alpha: 0.34), size: size)
        f.zPosition = 70; f.position = .zero; cam.addChild(f)
        f.run(.sequence([.fadeOut(withDuration: 0.35), .removeFromParent()]))
        cam.run(.sequence([.move(by: CGVector(dx: 6, dy: 0), duration: 0.03), .move(by: CGVector(dx: -10, dy: 0), duration: 0.05), .move(by: CGVector(dx: 4, dy: 0), duration: 0.03)]))
    }

    private func endDeployment(aborted: Bool) {
        guard model?.phase == .playing else { return }
        let t = Int(runTime.rounded())
        model?.timeSec = t
        model?.kills = kills
        model?.level = level
        let report = SurveyScoreEngine.compute(
            mission: runMission, timeSec: t, vouchers: detectionVouchers, aborted: aborted,
            traineeMode: GameSettings.traineeMode
        )
        model?.surveyReport = report
        model?.coresEarned = MetaStore.coresForRun(kills: kills, timeSec: t)
        model?.meta.awardRun(kills: kills, timeSec: t)
        let newScore = model?.meta.awardSurveyScore(report.surveyScore) == true
        model?.surveyScoreBest = newScore
        model?.runWasNewBest = newScore
        let lines = EngagementCopy.deathLines(report: report, isNewBestScore: newScore)
        model?.deathHeadline = lines.headline
        model?.deathSubline = lines.subline
        if GameCenterLogic.shouldSubmitScoreLeaderboard(newBest: newScore, score: report.surveyScore) {
            Task { @MainActor in GameCenterManager.shared.submitBestSurveyScore(report.surveyScore) }
        }
        let speciesSeen = Set(detectionVouchers.map(\.speciesId))
        model?.catalog.markDeploymentRecorded(speciesIds: speciesSeen, deployMode: deployMode)
        if aborted {
            SfxPlayer.shared.death(); Haptics.shared.death()
        } else {
            SfxPlayer.shared.levelUp(); Haptics.shared.levelUp()
        }
        model?.phase = .dead
        model?.activeMission = nil
        sticking = false; moveDir = .zero; stickBase.isHidden = true; stickKnob.isHidden = true
    }

    // MARK: - Level up choices

    private func levelUp() {
        let choices = pickChoices()
        model?.choices = choices
        sticking = false; moveDir = .zero; stickBase.isHidden = true; stickKnob.isHidden = true
        SfxPlayer.shared.levelUp(); Haptics.shared.levelUp()
        model?.phase = .levelUp
        if autopilotMovement, let first = choices.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.applyUpgrade(first.id) }
        }
    }
    private func pickChoices() -> [UpgradeCard] {
        var pool: [UpgradeCard] = []
        for id in AcousticFieldCatalog.kitPoolIds {
            if let card = AcousticFieldCatalog.kitCard(
                id: id, orbitLevel: orbitLevel, novaLevel: novaLevel, chainLevel: chainLevel,
                leechLevel: leechLevel, boltPierce: boltPierce, regen: regen
            ) {
                pool.append(card)
            }
        }
        pool.shuffle()
        return Array(pool.prefix(3))
    }

    // MARK: - Listen burst (spectrogram + extended detection)

    func triggerListenBurst() {
        guard model?.phase == .playing, listenCooldown <= 0 else { return }
        listenBurstTimer = 1.35
        listenCooldown = 2.75
        listenRecentTimer = 2.2
        let detectR = BalanceEngine.detectionRadius(
            pickupRadius: pickupRadius, orbitLevel: orbitLevel, chainLevel: chainLevel,
            deployMode: deployMode, listenBurstActive: true
        )
        let hearR = BalanceEngine.hearRadius(detectionRadius: detectR)
        var nearby: [ProjectSpecies] = []
        var nearest: Enemy?
        var nearestD = CGFloat.greatestFiniteMagnitude
        for e in enemies {
            let dx = e.node.position.x - pPos.x, dy = e.node.position.y - pPos.y
            let d = (dx * dx + dy * dy).squareRoot()
            guard d <= hearR else { continue }
            nearby.append(e.projectSpecies)
            if d < nearestD {
                nearestD = d
                nearest = e
            }
        }
        spectrogramSeed &+= 17
        model?.spectrogram = SpectrogramBuilder.snapshot(
            nearby: nearby, deployMode: deployMode, seed: spectrogramSeed
        )
        if let e = nearest {
            let dx = e.node.position.x - pPos.x
            let pan = Float(max(-1, min(1, dx / max(nearestD, 1))))
            SpeciesCallSynth.shared.play(
                species: ProjectSpeciesCatalog.surveySpecies(for: e.projectSpecies),
                pan: pan,
                volume: 0.58
            )
        }
        SfxPlayer.shared.nova()
    }

    // MARK: - HUD publish

    private func publishHUD() {
        model?.hp = max(0, Int(hp)); model?.maxHp = Int(maxHp)
        model?.xp = xp; model?.xpToNext = xpToNext
        let sec = Int(runTime)
        model?.nextGoalHint = BalanceEngine.nextGoalHint(timeSec: sec, kills: kills)
        timeLabel.text = String(format: "%d:%02d", sec / 60, sec % 60)
        killLabel.text = "\(kills) detections · \(model?.speciesRichness ?? 0) spp"
        lvlLabel.text = "RANK \(level) · \(SurveyProtocolCopy.noiseBudgetLabel) \(model?.noiseBudgetPct ?? 100)%"
        model?.noiseBudgetPct = max(0, Int((hp / max(maxHp, 1) * 100).rounded()))
        layoutHUD()
    }

    // MARK: - Touch (floating joystick)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard model?.phase == .playing, let t = touches.first else { return }
        stickAnchor = t.location(in: cam)
        stickBase.position = stickAnchor; stickKnob.position = stickAnchor
        stickBase.isHidden = false; stickKnob.isHidden = false; sticking = true
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard sticking, let t = touches.first else { return }
        let loc = t.location(in: cam)
        var dx = loc.x - stickAnchor.x, dy = loc.y - stickAnchor.y
        let mag = (dx*dx + dy*dy).squareRoot(); let maxR: CGFloat = 52
        if mag > maxR { dx = dx/mag*maxR; dy = dy/mag*maxR }
        stickKnob.position = CGPoint(x: stickAnchor.x + dx, y: stickAnchor.y + dy)
        moveDir = CGVector(dx: dx/maxR, dy: dy/maxR)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { endStick() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { endStick() }
    private func endStick() {
        sticking = false; moveDir = .zero
        stickBase.isHidden = true; stickKnob.isHidden = true
    }

    override func didChangeSize(_ oldSize: CGSize) {
        if cam.parent != nil { layoutHUD() }
    }
}

// MARK: - Testing harness (drives shipped update/combat/die path in unit tests)

extension GameScene {
    var testingAutopilotMovement: Bool {
        get { autopilotMovement }
        set { autopilotMovement = newValue }
    }

    var testingPlayerInvulnerable: Bool {
        get { playerInvulnerable }
        set { playerInvulnerable = newValue }
    }

    var testingCasualAutopilot: Bool {
        get { casualAutopilot }
        set { casualAutopilot = newValue }
    }

    func testing_setSpawnSeed(_ seed: UInt64) {
        spawnRng = SeededRNG(seed: seed)
    }

    var testingHp: CGFloat { hp }
    var testingRunTime: CGFloat { runTime }
    var testingBossSpawned: Bool { bossSpawned }
    var testingEnemyCount: Int { enemies.count }
    var testingKills: Int { kills }
    var testingLevel: Int { level }

    func testing_attach(to view: SKView) {
        scaleMode = .resizeFill
        if view.scene !== self { view.presentScene(self) }
    }

    func testing_applyRunProfile(_ profile: BuildProfile) {
        switch profile {
        case .metaBoosted:
            dmgMult = max(dmgMult, 1.15)
            xpMult = max(xpMult, 1.08)
            maxHp += 16
            hp += 16
        case .leechTank:
            maxHp += 28
            hp += 28
            leechLevel = 1
        default:
            break
        }
    }

    func testing_resolveLevelUpIfNeeded(preferring profile: BuildProfile? = nil) {
        guard model?.phase == .levelUp else { return }
        let pick: String?
        if let profile {
            let preferred = BuildState.preferredUpgrade(for: profile)
            if model?.choices.contains(where: { $0.id == preferred }) == true {
                pick = preferred
            } else {
                pick = model?.choices.first?.id
            }
        } else {
            pick = model?.choices.first?.id
        }
        if let id = pick {
            applyUpgrade(id)
        } else {
            model?.phase = .playing
        }
    }

    func testing_step(at time: TimeInterval, profile: BuildProfile? = nil) {
        update(time)
        testing_resolveLevelUpIfNeeded(preferring: profile ?? testingRunProfile)
    }

    func testing_suppressOffense() {
        boltInterval = 999
        boltDmg = 0
        novaLevel = 0
        chainLevel = 0
        orbitLevel = 0
    }

    func testing_placeEnemyOnPlayer(kind: EnemyKind, runTime: CGFloat = 20) {
        let stats = BalanceEngine.enemyStats(kind: kind, runTime: runTime)
        let sz: CGFloat = kind == .boss ? 64 : 22
        let color: SKColor = {
            switch kind {
            case .fast: return C.fast
            case .tank: return C.tank
            case .shooter: return C.shooter
            case .boss: return C.boss
            default: return C.basic
            }
        }()
        let node = SKSpriteNode(color: color, size: CGSize(width: sz, height: sz))
        node.position = pPos
        node.zPosition = 2
        addChild(node)
        let species = ProjectSpeciesCatalog.pick(archetype: kind.rawValue, roll: 0.3)
        enemies.append(Enemy(node: node, hp: stats.hp, speed: stats.speed, radius: stats.radius,
                           dmg: stats.damage, xp: stats.xp, kind: kind.rawValue, speciesId: species.id))
    }

    func testing_placeEnemyShotOnPlayer(damage: CGFloat) {
        let node = SKSpriteNode(color: C.shooter, size: CGSize(width: 10, height: 10))
        node.position = pPos
        node.zPosition = 3
        addChild(node)
        enemyShots.append(EnemyShot(node: node, vel: .zero, dmg: damage, life: 2))
    }

    func testing_fastForward(
        seconds: CGFloat,
        step: TimeInterval = 1.0 / 60.0,
        maxSteps: Int = 12_000,
        profile: BuildProfile? = nil
    ) {
        let build = profile ?? testingRunProfile
        var t = lastTime == 0 ? 0 : lastTime
        var steps = 0
        while runTime < seconds, model?.phase != .dead, steps < maxSteps {
            if model?.phase == .levelUp {
                testing_resolveLevelUpIfNeeded(preferring: build)
            } else {
                t += step
                update(t)
                testing_resolveLevelUpIfNeeded(preferring: build)
            }
            steps += 1
        }
    }

    func testing_captureSummary(
        profile: BuildProfile = .baseline,
        seed: UInt64 = 0,
        mode: HeadlessRunMode = .mortal
    ) -> GameSceneRunSummary {
        let metaLevels = model.map { store in
            MetaCatalog.all.reduce(0) { $0 + store.meta.level(for: $1.id) }
        } ?? 0
        return GameSceneRunSummary(
            profile: profile.rawValue,
            seed: seed,
            mode: mode.rawValue,
            metaLevels: metaLevels,
            survivalSec: Int(runTime.rounded(.down)),
            kills: kills,
            level: level,
            died: model?.phase == .dead,
            bossSpawned: bossSpawned,
            milestone30: hitMilestones.contains(30),
            milestone60: hitMilestones.contains(60),
            finalHp: max(0, Int(hp)),
            autopilotMovement: autopilotMovement,
            playerInvulnerable: playerInvulnerable,
            casualAutopilot: casualAutopilot
        )
    }
}

private extension SKSpriteNode {
    func glowFor() { /* gems read fine as flat squares; hook kept for tuning */ }
}
