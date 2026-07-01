# SWARM

> Outlast the horde. A native-iOS roguelite survivor (Vampire Survivors lineage), built in
> Swift + SpriteKit.

You drag to move; your weapons fire on their own. Enemies pour in from every side, drop XP when
they die, and you level up to pick build-defining upgrades. The longer you last, the deadlier it
gets. One life. Beat your best time.

## Status
- **Beta-ready (0.9.0)** — TestFlight tooling, unit tests, CI, Game Center leaderboard, shareable death card, settings.
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
xcodegen generate
xcodebuild -project SWARM.xcodeproj -scheme SWARM -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```
Unit tests:
```bash
cd ios
xcodegen generate
xcodebuild test -project SWARM.xcodeproj -scheme SWARM -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
```

## TestFlight
Beta tester instructions: **[TESTING.md](TESTING.md)**

### App Store Connect checklist (first upload)
1. **Developer portal** — Register App ID `ai.swarm.game` with **Game Center** capability enabled.
2. **App Store Connect** — Create app record (bundle ID `ai.swarm.game`, Games category).
3. **Leaderboard** — Create `ai.swarm.game.besttime`: integer score, sort **high-to-low** (survival seconds).
4. **Build number** — Increment `CURRENT_PROJECT_VERSION` in `ios/project.yml` before each upload (ASC rejects duplicate builds).
5. **Privacy** — App Privacy questionnaire: no tracking; local game progress; Game Center gameplay data for leaderboard.
6. **Export compliance** — App uses only standard Apple APIs (`ITSAppUsesNonExemptEncryption: false` in Info.plist).
7. **Beta review** — External TestFlight needs Beta App Review; note that Game Center sign-in is optional (offline play works).

Build an App Store IPA for upload:
```bash
chmod +x scripts/build-testflight.sh   # one-time
DEVELOPMENT_TEAM=YOUR_TEAM_ID ./scripts/build-testflight.sh
```
The script writes `build/export/ExportOptions.plist` with your team ID — there is no separate checked-in export plist. Requires Xcode with your Apple ID signed in (Settings → Accounts) and automatic signing. Upload the IPA with **Transporter** (recommended) or `xcrun iTMSTransporter`.

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
      ├─ Game/GameCenterManager.swift  Leaderboard auth + best-time submit
      ├─ Game/GameSettings.swift   Sound / haptics toggles (UserDefaults)
      ├─ Views/Overlays.swift      Menu / level-up / game-over / meta / settings UI
      ├─ Views/ShareCard.swift     Shareable death-summary card renderer
      └─ Resources/                Assets.xcassets (app icon + accent)
```

## QA / capture hook
Launching with the `SWARM_AUTOSTART=1` environment variable auto-starts a run and drives a kiting
auto-pilot (damage-immune) for headless screenshots. Gated entirely by that env var — safe to leave in.

## Next steps (toward a shippable hit)
- More weapons + enemy archetypes; second boss tier.
- App Store release after beta feedback.
- Custom art pass + soundtrack.