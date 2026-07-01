# SWARM

> Outlast the horde. A native-iOS roguelite survivor (Vampire Survivors lineage), built in
> Swift + SpriteKit.

You drag to move; your weapons fire on their own. Enemies pour in from every side, drop XP when
they die, and you level up to pick build-defining upgrades. The longer you last, the deadlier it
gets. One life. Beat your best time.

## Status
- **Real, working iOS app** — compiles, runs on simulator, full loop:
  menu → play → level-up choices → death → stats → retry.
- Flat neon geometry (no art-asset dependency), camera-follow world, in-scene HUD.
- **Meta-progression** — earn cores each run, spend them on permanent upgrades between runs.
- **Juice** — procedural SFX, Core Haptics, floating damage numbers, boss warning at 90s.

## Gameplay
- **Move:** floating joystick — touch anywhere and drag.
- **Attack:** automatic. The default Bolt auto-targets the nearest enemy.
- **Level up:** kills drop green XP gems; collect them to level up and choose 1 of 3 upgrades.
- **Build variety:**
  - *Bolt* — Sharper Bolts (+dmg), Rapid Fire (rate), Split Shot (+projectile), Piercing.
  - *Orbital Blades* — spinning melee that scales with count + damage.
  - *Shock Nova* — periodic radial pulse; faster + wider.
  - *Chain Lightning* — arcs between nearby foes; faster + higher voltage.
  - *Passives* — Vitality (max HP), Swift Feet (speed), Magnet (pickup range), Regeneration.
- **Enemies:** basic chasers, fast skirmishers (28s+), tanks (60s+), ranged shooters (45s+).
- **Boss:** arrives at **1:30** — high HP, triple-shot barrage, big XP payout.
- **Escalation:** spawn rate, batch size, enemy HP and damage all ramp with time.
- **Meta shop:** spend cores on permanent damage, HP, speed, and magnet bonuses.

## Run it
```bash
brew install xcodegen          # one-time
cd ios && xcodegen generate    # writes SWARM.xcodeproj from project.yml
open SWARM.xcodeproj           # set your signing Team for device, then Run
```
Simulator build (no signing):
```bash
cd ios
xcodebuild -project SWARM.xcodeproj -scheme SWARM -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

## Layout
```
swarm/
└─ ios/
   ├─ project.yml                  XcodeGen spec (iOS 16+, portrait)
   └─ SWARM/
      ├─ App/SwarmApp.swift        App entry; hosts SpriteView + SwiftUI overlays
      ├─ Game/GameModel.swift      ObservableObject bridge (phase, HUD, upgrade choices)
      ├─ Game/GameScene.swift      All gameplay (movement, weapons, hordes, XP, juice)
      ├─ Game/Feedback.swift       Procedural SFX + Core Haptics
      ├─ Game/MetaStore.swift      Cores + permanent upgrades (UserDefaults)
      ├─ Views/Overlays.swift      Menu / level-up / game-over / meta shop UI
      └─ Resources/                Assets.xcassets (app icon + accent)
```

## QA / capture hook
Launching with the `SWARM_AUTOSTART=1` environment variable auto-starts a run and drives a kiting
auto-pilot (damage-immune) for headless screenshots. Gated entirely by that env var — safe to leave in.

## Next steps (toward a shippable hit)
- Game Center leaderboard (best survival time) + shareable death card.
- More weapons + enemy archetypes; second boss tier.
- TestFlight (needs Apple Developer signing).
- Custom art pass + soundtrack.