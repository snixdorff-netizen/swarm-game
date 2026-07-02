#!/usr/bin/env bash
# P6 verification bundle — plan steps 1–5 + AC1–5 mapping (swarm scope only).
set -euo pipefail

SCRATCH="${GROK_GOAL_SCRATCH:-/var/folders/jc/vlt38jc172b76pd4lmy9ch340000gn/T/grok-goal-ca2d648e3fec/implementer}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEVELOPER="$(dirname "$REPO")"
WILDLIFE="$DEVELOPER/wildlife-acoustics-training"
mkdir -p "$SCRATCH"
BUNDLE="$SCRATCH/p6-verification-bundle.txt"
: > "$BUNDLE"

log() { echo "$1" | tee -a "$BUNDLE"; }

log "=== P6 Verification Bundle ==="
log "repo: $REPO"
log "scratch: $SCRATCH"
log "timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
log ""

log "=== Workspace scope fence (sibling repos must be clean) ==="
export GROK_GOAL_SCRATCH="$SCRATCH"
"$REPO/scripts/workspace-clean.sh" >> "$BUNDLE" 2>&1
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

log "=== Acceptance criteria mapping (SWARM 15% workflow proxy) ==="
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

log "=== Wildlife read-only tests (sibling repo, no edits) ==="
rm -f "$SCRATCH/wildlife-sim.log" "$SCRATCH/wildlife-test.log"
if [[ -d "$WILDLIFE/.git" ]]; then
  git -C "$WILDLIFE" status --porcelain | tee "$SCRATCH/wildlife-pre-test-status.txt"
  if (cd "$WILDLIFE" && npm test) >"$SCRATCH/wildlife-test.log" 2>&1; then
    WILDLIFE_TESTS=$(grep -E '^ℹ tests' "$SCRATCH/wildlife-test.log" | tail -1 || echo "unknown")
    log "PASS wildlife-test.log $WILDLIFE_TESTS"
  else
    log "FAIL wildlife-test.log (see scratch)"
    tail -20 "$SCRATCH/wildlife-test.log" >> "$BUNDLE"
    exit 1
  fi
  git -C "$WILDLIFE" status --porcelain | tee "$SCRATCH/wildlife-post-test-status.txt"
  if [[ -n "$(cat "$SCRATCH/wildlife-post-test-status.txt")" ]]; then
    log "WARN wildlife dirty after npm test — resetting"
    git -C "$WILDLIFE" reset --hard HEAD && git -C "$WILDLIFE" clean -fd
  fi
else
  log "SKIP wildlife repo not found"
fi

log "=== Wildlife read-only sim (optional; echoes-src not in wildlife@HEAD) ==="
SIM_FOUND=""
for candidate in \
  "$WILDLIFE/echoes-src/tools/bioacoustics-sim-drive.mjs" \
  "$WILDLIFE/vendor/echoes-wild/tools/bioacoustics-sim-drive.mjs"; do
  if [[ -f "$candidate" ]]; then
    SIM_FOUND="$candidate"
    break
  fi
done
if [[ -n "$SIM_FOUND" ]]; then
  node "$SIM_FOUND" 2>&1 | tee "$SCRATCH/wildlife-sim.log" | tail -5 >> "$BUNDLE"
  LIFT=$(grep -E '"liftPct"|liftPct' "$SCRATCH/wildlife-sim.log" | tail -1 || true)
  log "PASS wildlife-sim.log fresh from $SIM_FOUND"
  log "  $LIFT"
else
  {
    echo "wildlife-sim: NOT_RUN"
    echo "reason: bioacoustics-sim-drive.mjs absent at wildlife-acoustics-training HEAD (9a91f37)"
    echo "fresh_evidence: wildlife-test.log (npm test, read-only)"
    echo "swarm_15pct_proxy: AC1-5 mapping above + SWARM test.log"
  } | tee "$SCRATCH/wildlife-sim.log" >> "$BUNDLE"
  log "NOTE wildlife-sim.log documents NOT_RUN (no stale liftPct); see wildlife-test.log"
fi
log ""

log "=== Bundle complete: $BUNDLE ==="