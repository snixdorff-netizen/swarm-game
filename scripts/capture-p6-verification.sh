#!/usr/bin/env bash
# P6 verification bundle — plan steps 1–5 + AC1–5 mapping (no uplift meta-layer).
set -euo pipefail

SCRATCH="${GROK_GOAL_SCRATCH:-/var/folders/jc/vlt38jc172b76pd4lmy9ch340000gn/T/grok-goal-ca2d648e3fec/implementer}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$SCRATCH"
BUNDLE="$SCRATCH/p6-verification-bundle.txt"
: > "$BUNDLE"

log() { echo "$1" | tee -a "$BUNDLE"; }

log "=== P6 Verification Bundle ==="
log "repo: $REPO"
log "scratch: $SCRATCH"
log "timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
log ""

log "=== Scope (swarm commits since P5 baseline f45cf29) ==="
git -C "$REPO" diff --name-only f45cf29..HEAD | tee "$SCRATCH/scope-clean.log" >> "$BUNDLE"
log ""

log "=== Verification step 1: build ==="
cd "$REPO/ios"
xcodegen generate >/dev/null
if xcodebuild -project SWARM.xcodeproj -scheme SWARM -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build \
  >"$SCRATCH/build.log" 2>&1; then
  log "PASS build (see build.log)"
else
  log "FAIL build (see build.log)"
  exit 1
fi
log ""

log "=== Verification steps 2–3: xcodebuild test ==="
if xcodebuild test -project SWARM.xcodeproj -scheme SWARM -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO \
  >"$SCRATCH/test.log" 2>&1; then
  TEST_LINE=$(grep -E 'Executed [0-9]+ tests' "$SCRATCH/test.log" | tail -1)
  log "PASS $TEST_LINE"
  log "PASS TEST SUCCEEDED"
else
  log "FAIL tests (see test.log)"
  exit 1
fi
log ""

log "=== Verification step 4: simulator launch ==="
export GROK_GOAL_SCRATCH="$SCRATCH"
if "$REPO/scripts/verify-simulator-launch.sh" >>"$SCRATCH/launch.log" 2>&1; then
  log "PASS launch (see launch.log)"
else
  log "WARN launch failed — see launch.log (steps 2–3 accepted bar)"
fi
log ""

log "=== Verification step 5: structural source check ==="
{
  echo "--- vet panel queue position ---"
  grep -n "queueLabel\|Clip.*of" "$REPO/ios/SWARM/Views/Overlays.swift" "$REPO/ios/SWARM/Game/AnalystLoop.swift" || true
  echo "--- mission brief site + recorder ---"
  grep -n "siteLabel\|recorderProfile\|vetBacklogCount" "$REPO/ios/SWARM/Views/Overlays.swift" "$REPO/ios/SWARM/Game/GameModel.swift" || true
  echo "--- presence night-card CSV header ---"
  grep -n "presenceAbsenceNightCard\|presence_absence" "$REPO/ios/SWARM/Game/SurveyReportExporter.swift" "$REPO/ios/SWARM/Game/SurveyProtocolCopy.swift" || true
} | tee "$SCRATCH/structure.log" >> "$BUNDLE"
log ""

log "=== Acceptance criteria mapping ==="
log "AC1 Batch analyst vetting"
log "  grep: AnalystLoop.swift queueLabel + advanceAfterDecision decidedIndex"
log "  test: AnalystLoopTests.testDeferThenResolveAdvancesFromNonHeadPosition"
log "  log:  $(grep -c 'testDeferThenResolveAdvancesFromNonHeadPosition.*passed' "$SCRATCH/test.log" 2>/dev/null || echo 0) pass line(s)"
log ""
log "AC2 Live analyst backlog visibility"
log "  grep: Overlays.swift vetBacklogCount"
log "  test: AnalystLoopTests.testVetQueuePreservesEncounterOrder"
log "  log:  $(grep -c 'testVetQueuePreservesEncounterOrder.*passed' "$SCRATCH/test.log" 2>/dev/null || echo 0) pass line(s)"
log ""
log "AC3 Presence/absence lab export"
log "  grep: SurveyReportExporter.swift presenceAbsenceNightCardCSVHeader"
log "  test: SurveyReportExporterTests.testCSVRowsIncludeHeaderAndVoucherLine"
log "  log:  $(grep -c 'SurveyReportExporterTests.*passed' "$SCRATCH/test.log" 2>/dev/null || echo 0) pass line(s)"
log ""
log "AC4 Configure-step completeness"
log "  grep: Overlays.swift siteLabel · recorderProfile"
log "  test: TransectModeTests.testDeploymentContextIsDeterministicFromSeed"
log "  log:  $(grep -c 'testDeploymentContextIsDeterministicFromSeed.*passed' "$SCRATCH/test.log" 2>/dev/null || echo 0) pass line(s)"
log ""
log "AC5 Ship quality preserved"
log "  build: PASS (step 1)"
log "  test:  $TEST_LINE"
log ""

log "=== Wildlife read-only sim (context only) ==="
WILDLIFE_SIM="$REPO/../wildlife-acoustics-training/echoes-src/tools/bioacoustics-sim-drive.mjs"
if [[ -f "$WILDLIFE_SIM" ]]; then
  node "$WILDLIFE_SIM" 2>&1 | tee "$SCRATCH/wildlife-sim.log" | tail -3 >> "$BUNDLE"
  log "PASS wildlife-sim.log captured"
else
  log "SKIP wildlife sim script not found"
fi
log ""
log "=== Bundle complete: $BUNDLE ==="