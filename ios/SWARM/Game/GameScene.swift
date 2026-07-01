// SWARM — the gameplay scene. Top-down roguelite survivor:
// move with a floating joystick, weapons auto-fire, hordes chase you, kills drop XP,
// level up to pick build upgrades. Escalating difficulty until you die.
//
// Rendered in flat neon geometry (no art assets needed). Camera follows the player; HUD
// is attached to the camera so it stays fixed on screen.

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
    var kind: Int          // 0 basic, 1 fast, 2 tank, 3 shooter, 9 boss
    var flash: CGFloat = 0
    var shootTimer: CGFloat = 0
    init(node: SKSpriteNode, hp: CGFloat, speed: CGFloat, radius: CGFloat, dmg: CGFloat, xp: CGFloat, kind: Int = 0) {
        self.node = node; self.hp = hp; self.maxHp = hp; self.speed = speed
        self.radius = radius; self.dmg = dmg; self.xp = xp; self.kind = kind
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
    static let bg = SKColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1)
    static let grid = SKColor(red: 0.12, green: 0.13, blue: 0.22, alpha: 1)
    static let player = SKColor(red: 0.20, green: 0.88, blue: 1.0, alpha: 1)
    static let bolt = SKColor(red: 0.85, green: 0.97, blue: 1.0, alpha: 1)
    static let basic = SKColor(red: 1.0, green: 0.30, blue: 0.42, alpha: 1)
    static let fast = SKColor(red: 1.0, green: 0.66, blue: 0.30, alpha: 1)
    static let tank = SKColor(red: 0.69, green: 0.42, blue: 1.0, alpha: 1)
    static let shooter = SKColor(red: 1.0, green: 0.45, blue: 0.75, alpha: 1)
    static let boss = SKColor(red: 0.95, green: 0.15, blue: 0.55, alpha: 1)
    static let gem = SKColor(red: 0.71, green: 1.0, blue: 0.36, alpha: 1)
    static let chain = SKColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 1)
    static let orbit = SKColor(red: 0.20, green: 0.88, blue: 1.0, alpha: 1)
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
    private var dmgMult: CGFloat = 1

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
    private var autoDrive = false   // env-gated: drives movement for headless gameplay capture

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
        if ProcessInfo.processInfo.environment["SWARM_AUTOSTART"] != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.startRun(); self?.autoDrive = true
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
        g.strokeColor = C.grid; g.lineWidth = 1; g.zPosition = -10
        gridNode.addChild(g)
        addChild(gridNode)
    }

    private func buildPlayer() {
        let r: CGFloat = 13
        let path = CGMutablePath()
        path.move(to: CGPoint(x: r * 1.3, y: 0))
        path.addLine(to: CGPoint(x: -r, y: r * 0.85))
        path.addLine(to: CGPoint(x: -r * 0.4, y: 0))
        path.addLine(to: CGPoint(x: -r, y: -r * 0.85))
        path.closeSubpath()
        player = SKShapeNode(path: path)
        player.fillColor = C.player
        player.strokeColor = .white
        player.lineWidth = 1.5
        player.glowWidth = 4
        player.zPosition = 5
        addChild(player)
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
        hpBarBg = bar(SKColor(white: 1, alpha: 0.12)); hpBar = bar(SKColor(red: 0.95, green: 0.25, blue: 0.35, alpha: 1))
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
        let meta = model?.meta
        dmgMult = meta?.damageMult ?? 1
        hp = 100 + (meta?.bonusHp ?? 0); maxHp = hp
        moveSpeed = 178 * (meta?.speedMult ?? 1)
        pickupRadius = 78 + (meta?.bonusMagnet ?? 0); regen = 0
        boltDmg = 12; boltInterval = 0.72; boltTimer = 0; boltCount = 1; boltPierce = 0
        orbitLevel = 0; orbitDmg = 10; novaLevel = 0; novaDmg = 16; novaRadius = 110; novaInterval = 1.6
        chainLevel = 0; chainDmg = 14; chainInterval = 1.4; chainTimer = 0
        novaRing.path = CGPath(ellipseIn: CGRect(x: -novaRadius, y: -novaRadius, width: novaRadius*2, height: novaRadius*2), transform: nil)
        level = 1; xp = 0; xpToNext = 6; runTime = 0; kills = 0; spawnTimer = 0
        pPos = .zero; player.position = .zero; player.zRotation = 0
        cam.position = .zero
        publishHUD(); layoutHUD()
        setChrome(true)
        for _ in 0..<6 { spawnOne() }
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
        if autoDrive {
            if let e = nearestEnemy() {
                let dx = pPos.x - e.node.position.x, dy = pPos.y - e.node.position.y
                let d = max(1, (dx*dx + dy*dy).squareRoot())
                moveDir = CGVector(dx: dx/d * 0.85 - dy/d * 0.5, dy: dy/d * 0.85 + dx/d * 0.5)
            } else { moveDir = CGVector(dx: cos(runTime), dy: sin(runTime)) }
        }
        if regen > 0 && hp < maxHp { hp = min(maxHp, hp + regen * dt) }
        if hurtCooldown > 0 { hurtCooldown -= dt }

        // Move player
        pPos.x += moveDir.dx * moveSpeed * dt
        pPos.y += moveDir.dy * moveSpeed * dt
        player.position = pPos
        cam.position = pPos

        updateAim()
        spawn(dt)
        maybeBoss()
        updateEnemies(dt)
        fireWeapons(dt)
        updateProjectiles(dt)
        updateEnemyShots(dt)
        updateOrbit(dt)
        updateGems(dt)

        if model?.phase == .levelUp {
            publishHUD()
            return
        }
        if hp <= 0 { die() ; return }
        publishHUD()
        if Int(runTime) != model?.timeSec { model?.timeSec = Int(runTime) }
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
        let interval = max(0.12, 0.5 - runTime * 0.005)
        if spawnTimer <= 0 && enemies.count < maxEnemies {
            spawnTimer = interval
            let batch = 2 + Int(runTime / 18)
            for _ in 0..<batch { spawnOne() }
        }
    }
    private func spawnOne() {
        let ang = CGFloat.random(in: 0..<(2 * .pi))
        let dist = max(size.width, size.height) * 0.56
        let pos = CGPoint(x: pPos.x + cos(ang) * dist, y: pPos.y + sin(ang) * dist)
        let t = runTime
        var kind = 0
        let roll = CGFloat.random(in: 0..<1)
        if t > 60 && roll < 0.16 { kind = 2 }
        else if t > 45 && roll < 0.28 { kind = 3 }
        else if t > 28 && roll < 0.42 { kind = 1 }
        let scale = 1 + t * 0.012
        var color = C.basic, hpv: CGFloat = 18, spd: CGFloat = 52, rad: CGFloat = 12, dmg: CGFloat = 8, xpv: CGFloat = 1, sz: CGFloat = 22
        if kind == 1 { color = C.fast; hpv = 12; spd = 96; rad = 9; dmg = 7; xpv = 1; sz = 16 }
        if kind == 2 { color = C.tank; hpv = 70; spd = 34; rad = 19; dmg = 16; xpv = 3; sz = 36 }
        if kind == 3 { color = C.shooter; hpv = 22; spd = 38; rad = 11; dmg = 5; xpv = 2; sz = 18 }
        hpv *= scale; dmg *= (1 + t * 0.004)
        let node = SKSpriteNode(color: color, size: CGSize(width: sz, height: sz))
        node.position = pos; node.zRotation = .pi/4; node.zPosition = 2
        if kind == 3 { node.zRotation = 0 }
        addChild(node)
        enemies.append(Enemy(node: node, hp: hpv, speed: spd, radius: rad, dmg: dmg, xp: xpv, kind: kind))
    }

    private func maybeBoss() {
        guard !bossSpawned, runTime >= 90 else { return }
        bossSpawned = true
        spawnBoss()
    }

    private func spawnBoss() {
        SfxPlayer.shared.boss(); Haptics.shared.boss()
        bossWarnLabel.text = "⚠ BOSS INCOMING"
        bossWarnLabel.isHidden = false
        bossWarnLabel.run(.sequence([.wait(forDuration: 2.2), .fadeOut(withDuration: 0.4), .run { [weak self] in self?.bossWarnLabel.isHidden = true; self?.bossWarnLabel.alpha = 1 }]))
        let ang = CGFloat.random(in: 0..<(2 * .pi))
        let dist = max(size.width, size.height) * 0.5
        let pos = CGPoint(x: pPos.x + cos(ang) * dist, y: pPos.y + sin(ang) * dist)
        let scale = 1 + runTime * 0.012
        let hpv: CGFloat = 420 * scale
        let node = SKSpriteNode(color: C.boss, size: CGSize(width: 64, height: 64))
        node.position = pos; node.zRotation = .pi/4; node.zPosition = 6
        addChild(node)
        enemies.append(Enemy(node: node, hp: hpv, speed: 28, radius: 30, dmg: 28, xp: 18, kind: 9))
    }

    private func updateEnemies(_ dt: CGFloat) {
        for e in enemies {
            let dx = pPos.x - e.node.position.x, dy = pPos.y - e.node.position.y
            let d = max(1, (dx*dx + dy*dy).squareRoot())
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
                e.node.position.x += dx/d * e.speed * dt
                e.node.position.y += dy/d * e.speed * dt
            }
            if e.flash > 0 { e.flash -= dt; if e.flash <= 0 { e.node.colorBlendFactor = 0 } }
            if d < e.radius + 13 && hurtCooldown <= 0 {
                if !autoDrive { hp -= e.dmg; flashHurt() }
                hurtCooldown = 0.55
            }
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
                if !autoDrive { hp -= s.dmg; flashHurt() }
                hurtCooldown = 0.45
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
        e.node.removeFromParent()
        if let idx = enemies.firstIndex(where: { $0 === e }) { enemies.remove(at: idx) }
        kills += 1; model?.kills = kills
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
        xp += v
        if xp >= xpToNext {
            xp -= xpToNext; level += 1
            xpToNext = ceil(xpToNext * 1.28 + 3)
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

    private func die() {
        let t = Int(runTime.rounded())
        model?.timeSec = t
        model?.kills = kills
        model?.level = level
        model?.coresEarned = MetaStore.coresForRun(kills: kills, timeSec: t)
        if model?.meta.awardRun(kills: kills, timeSec: t) == true {
            GameCenterManager.shared.submitBestTime(t)
        }
        SfxPlayer.shared.death(); Haptics.shared.death()
        model?.phase = .dead
        sticking = false; moveDir = .zero; stickBase.isHidden = true; stickKnob.isHidden = true
    }

    // MARK: - Level up choices

    private func levelUp() {
        let choices = pickChoices()
        model?.choices = choices
        sticking = false; moveDir = .zero; stickBase.isHidden = true; stickKnob.isHidden = true
        SfxPlayer.shared.levelUp(); Haptics.shared.levelUp()
        model?.phase = .levelUp
        if autoDrive, let first = choices.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.applyUpgrade(first.id) }
        }
    }
    private func pickChoices() -> [UpgradeCard] {
        var pool: [UpgradeCard] = []
        pool.append(UpgradeCard(id: "bolt_dmg", title: "Sharper Bolts", subtitle: "+7 bolt damage", symbol: "bolt.fill", levelText: ""))
        pool.append(UpgradeCard(id: "bolt_rate", title: "Rapid Fire", subtitle: "Fire faster", symbol: "forward.fill", levelText: ""))
        pool.append(UpgradeCard(id: "bolt_count", title: "Split Shot", subtitle: "+1 bolt per volley", symbol: "arrow.up.and.down.and.arrow.left.and.right", levelText: ""))
        if boltPierce < 4 { pool.append(UpgradeCard(id: "bolt_pierce", title: "Piercing", subtitle: "Bolts pass through +1", symbol: "arrow.right.to.line", levelText: "")) }
        pool.append(UpgradeCard(id: orbitLevel == 0 ? "orbit" : "orbit", title: orbitLevel == 0 ? "Orbital Blades" : "More Blades", subtitle: orbitLevel == 0 ? "Spinning blades guard you" : "+1 orbiting blade", symbol: "circle.dashed", levelText: orbitLevel == 0 ? "NEW" : "Lv \(orbitLevel+1)"))
        if orbitLevel > 0 { pool.append(UpgradeCard(id: "orbit_dmg", title: "Heavy Blades", subtitle: "+blade damage", symbol: "circle.hexagongrid.fill", levelText: "")) }
        pool.append(UpgradeCard(id: novaLevel == 0 ? "nova" : "nova", title: novaLevel == 0 ? "Shock Nova" : "Faster Nova", subtitle: novaLevel == 0 ? "Pulse damages nearby foes" : "Pulse more often", symbol: "wave.3.right", levelText: novaLevel == 0 ? "NEW" : "Lv \(novaLevel+1)"))
        if novaLevel > 0 { pool.append(UpgradeCard(id: "nova_radius", title: "Wide Nova", subtitle: "+pulse radius", symbol: "circle.circle", levelText: "")) }
        pool.append(UpgradeCard(id: "max_hp", title: "Vitality", subtitle: "+25 max health", symbol: "heart.fill", levelText: ""))
        pool.append(UpgradeCard(id: "move", title: "Swift Feet", subtitle: "+move speed", symbol: "figure.run", levelText: ""))
        pool.append(UpgradeCard(id: "pickup", title: "Magnet", subtitle: "+pickup range", symbol: "scope", levelText: ""))
        if regen < 6 { pool.append(UpgradeCard(id: "regen", title: "Regeneration", subtitle: "Heal over time", symbol: "cross.case.fill", levelText: "")) }
        pool.append(UpgradeCard(id: chainLevel == 0 ? "chain" : "chain", title: chainLevel == 0 ? "Chain Lightning" : "Faster Arc", subtitle: chainLevel == 0 ? "Zap chains between foes" : "Arc more often", symbol: "bolt.horizontal.fill", levelText: chainLevel == 0 ? "NEW" : "Lv \(chainLevel+1)"))
        if chainLevel > 0 { pool.append(UpgradeCard(id: "chain_dmg", title: "High Voltage", subtitle: "+chain damage", symbol: "bolt.circle.fill", levelText: "")) }
        pool.shuffle()
        return Array(pool.prefix(3))
    }

    // MARK: - HUD publish

    private func publishHUD() {
        model?.hp = max(0, Int(hp)); model?.maxHp = Int(maxHp)
        model?.xp = xp; model?.xpToNext = xpToNext
        timeLabel.text = String(format: "%d:%02d", Int(runTime)/60, Int(runTime)%60)
        killLabel.text = "\(kills) kills"
        lvlLabel.text = "LV \(level)"
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

private extension SKSpriteNode {
    func glowFor() { /* gems read fine as flat squares; hook kept for tuning */ }
}
