# SWARM

> Outlast the horde. A native-iOS roguelite survivor (Vampire Survivors lineage), built in
> Swift + SpriteKit.

You drag to move; your weapons fire on their own. Enemies pour in from every side, drop XP when
they die, and you level up to pick build-defining upgrades. The longer you last, the deadlier it
gets. One life. Beat your best time.

## Status
- **Real, working iOS app** — compiles (`BUILD SUCCEEDED`), runs on the simulator, full loop:
  menu → play → level-up choices → death → stats → retry.
- Flat neon geometry (no art-asset dependency), camera-follow world, in-scene HUD.

## Gameplay
- **Move:** floating joystick — touch anywhere and drag.
- **Attack:** automatic. The default Bolt auto-targets the nearest enemy.
- **Level up:** kills drop green XP gems; collect them to level up and choose 1 of 3 upgrades.
- **Build variety:**
  - *Bolt* — Sharper Bolts (+dmg), Rapid Fire (rate), Split Shot (+projectile), Piercing.
  - *Orbital Blades* — spinning melee that scales with count + damage.
  - *Shock Nova* — periodic radial pulse; faster + wider.
  - *Passives* — Vitality (max HP), Swift Feet (speed), Magnet (pickup range), Regeneration.
- **Escalation:** spawn rate, batch size, enemy HP and damage all ramp with time; faster and
  tankier enemy types unlock at 28s and 60s.
- **Juice:** hit flashes, death bursts, screen shake + red flash on damage, neon glow, expanding
  nova rings, best-time persistence.

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
      ├─ Views/Overlays.swift      Menu / level-up / game-over UI (neon theme)
      └─ Resources/                Assets.xcassets (app icon + accent)
```

## QA / capture hook
Launching with the `SWARM_AUTOSTART=1` environment variable auto-starts a run and drives a kiting
auto-pilot (damage-immune) for headless screenshots. It is gated entirely by that env var and never
triggers in a normal launch — safe to leave in.

## Next steps (toward a shippable hit)
- Sound + Core Haptics (hit, level-up, death).
- More weapons + enemy types + a timed boss; floating damage numbers.
- Meta-progression between runs (permanent unlocks) — the retention engine for this genre.
- Game Center leaderboard (best survival time) + a shareable death card (viral hook).
- TestFlight (needs your Apple Developer signing).
