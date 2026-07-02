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
- **P3 trust wave** — voucher metadata (deployment ID, site, recorder, clip filename), coffee-break vs field-day transect toggle, lab board honesty label, README sync.
- **P4 credibility wave** — combat de-emphasis (no DPS floaters, auto-archived clips, drift-not-chase), passive SM5BAT monitor (stationary rig, crossing passes, emergence window).
- **P5 analyst loop** — Kaleidoscope-style vet panel (Confirm / Reject / Needs review), presence/absence rollup on game-over, conservative classifier toggle, CSV `auto_id`/`manual_id`/`vet_status` columns.
- **P6 batch analyst** — sequential vet queue (clip N of M), live analyst backlog on mission brief, presence/absence night-card lab export, configure-step brief (site + recorder + deployment ID).
- **Meta-progression** — earn survey grants each deployment, spend in Field Lab on permanent rig upgrades.

## Project species (12)
| Common name | Scientific name | Band |
|-------------|-----------------|------|
| Wood Thrush | *Hylocichla mustelina* | 2–5 kHz flute song |
| Ovenbird | *Seiurus aurocapilla* | 3–7 kHz teacher call |
| Scarlet Tanager | *Piranga olivacea* | 2–8 kHz burry phrases |
| Blackburnian Warbler | *Setophaga fusca* | 4–10 kHz thin trill |
| Cedar Waxwing | *Bombycilla cedrorum* | 5–12 kHz high buzz |
| American Bullfrog | *Lithobates catesbeianus* | 80–300 Hz jug-o-rum |
| Barred Owl | *Strix varia* | 120–500 Hz who-cooks |
| Northern Mockingbird | *Mimus polyglottos* | Variable mimic |
| Red-winged Blackbird | *Agelaius phoeniceus* | 1–4 kHz conk-a-ree |
| Little Brown Bat | *Myotis lucifugus* | 25–60 kHz† |
| Hoary Bat | *Lasiurus cinereus* | 20–45 kHz† |
| Big Brown Bat | *Eptesicus fuscus* | 30–80 kHz† |

## Gameplay
- **Move:** floating joystick on SM5 — walk the transect quietly. **SM5BAT** uses passive monitor mode (slow reposition, no chase).
- **Listen:** classifiers auto-scan; vocalizations drift into detection range (not horde chase). Tap **Listen** for spectrogram burst + higher-confidence IDs.
- **Identify:** confirmed detections log species with voucher metadata (deployment ID, site, recorder, pseudo-WAV clip name).
- **Transect modes:** **Coffee Break** (8-min slice, scaled targets) or **Field Day** (full 8–12 min protocol).
- **Rank up:** confirmed IDs archive automatically → choose 1 of 3 **field kit** modules.
- **Field kit:**
  - *Narrow-Beam Mic* — classifier gain, fast sampling, multi-channel array, band-pass filter.
  - *Perimeter Song Meters* — edge recorders orbiting your rig.
  - *Harmonic Sweep* — Kaleidoscope-style wideband scan.
  - *Call Relay Network* — chain IDs across distant callers.
  - *Passive Monitor* — recover signal clarity on confirm.
  - *Quiet Approach*, *Clip Magnet*, *Noise Floor Recovery*, *Field Stamina*.
- **Field Lab (meta):** Amp Gain, Rugged Housing, Quiet Trek, Kaleidoscope Reach, Catalog Accelerator, Passive Monitor.
- **Habitat sites:** Canopy Transect, Wetland Edge, Coastal Marsh — species pools shift per site.
- **Rare event @ 1:30:** endangered ultrasonic signature (SM5BAT-class).
- **Lab board:** async co-op feed (simulated lab mates disclosed in UI).

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
  Game/ProjectSpeciesCatalog.swift  12 project species with scientific names
  Game/TransectMode.swift           Coffee break vs field-day profiles
  Game/SurveyFieldProfile.swift     Acoustic transect vs passive bat behavior
  Game/GameScene.swift              Survey loop (detection, classifiers, clips)
  Game/BalanceEngine.swift          Spawn + detection + survey milestones
  Views/Overlays.swift              Deploy / Field Lab / survey end UI
```

## QA hooks
- `SWARM_AUTOSTART=1` — auto-deploy, invulnerable (QA screenshots)
- `SWARM_MORTAL_AUTOSTART=1` — mortal casual stalk for balance batch runs