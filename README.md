# SWARM — Acoustic Field

> **We listen.** A native-iOS bioacoustic field survey game inspired by professional wildlife
> monitoring workflows ([Wildlife Acoustics](https://www.wildlifeacoustics.com) — Song Meter
> deployments, ultrasonic bat surveys, Kaleidoscope-style classification).

Drag to reposition your **Song Meter** rig in the habitat. Auto-classifiers scan for hidden
vocalizations; confirmed detections drop **recording clips** you collect to rank up and expand your
field kit. Complete transect missions under protocol — noise budget ends the deployment early.
Beat your best **survey score**.

*Fan project / lineage game — not affiliated with Wildlife Acoustics, Inc.*

## Status
- **Beta-ready (0.9.0)** — TestFlight tooling, unit tests, CI, Game Center survey-score leaderboard, shareable survey card, settings.
- **P0 trust wave** — protocol vocabulary, mission briefs, mini-spectrogram waterfall, 12 project species, survey scoring.
- **P1 meaning wave** — detection vouchers, study notebook catalog, false-positive mimic penalty, SM5BAT night palette, report export.
- **P2 joy wave** — habitat sites, mentorship checklist, lab board, citizen-science CSV export, pause/gain/captions/colorblind spectrogram.
- **Meta-progression** — earn survey grants each deployment, spend in Field Lab on permanent rig upgrades.

## Gameplay
- **Move:** floating joystick — deploy quietly through the survey grid.
- **Listen:** classifiers auto-scan; fauna appear as you enter acoustic detection range.
- **Identify:** confirmed IDs log species (Passerine, Swift Trill, Resonant Drone, Echo Mimic…).
- **Rank up:** collect green recording clips → choose 1 of 3 **field kit** modules.
- **Field kit:**
  - *Narrow-Beam Mic* — classifier gain, fast sampling, multi-channel array, band-pass filter.
  - *Perimeter Song Meters* — edge recorders orbiting your rig.
  - *Harmonic Sweep* — Kaleidoscope-style wideband scan.
  - *Call Relay Network* — chain IDs across distant callers.
  - *Passive Monitor* — recover signal clarity on confirm.
  - *Quiet Approach*, *Clip Magnet*, *Noise Floor Recovery*, *Field Stamina*.
- **Field Lab (meta):** Amp Gain, Rugged Housing, Quiet Trek, Kaleidoscope Reach, Catalog Accelerator, Passive Monitor.
- **Rare event @ 1:30:** endangered ultrasonic signature (SM5BAT-class).

## Run it
```bash
brew install xcodegen
cd ios && xcodegen generate
open SWARM.xcodeproj
```

Simulator build:
```bash
cd ios && xcodegen generate
xcodebuild -project SWARM.xcodeproj -scheme SWARM -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

Unit tests:
```bash
cd ios && xcodebuild test -project SWARM.xcodeproj -scheme SWARM -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
```

## Layout
```
ios/SWARM/
  Game/AcousticFieldCatalog.swift   Species + field kit naming
  Game/GameScene.swift              Survey loop (detection, classifiers, clips)
  Game/BalanceEngine.swift          Spawn + detection + survey milestones
  Views/Overlays.swift              Deploy / Field Lab / survey end UI
```

## QA hooks
- `SWARM_AUTOSTART=1` — auto-deploy, invulnerable (QA screenshots)
- `SWARM_MORTAL_AUTOSTART=1` — mortal casual stalk for balance batch runs