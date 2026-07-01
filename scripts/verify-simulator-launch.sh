#!/usr/bin/env bash
# Verify SWARM launches on booted simulator: immortal QA (SWARM_AUTOSTART) + mortal casual path.
set -euo pipefail

SCRATCH="${GROK_GOAL_SCRATCH:-/var/folders/jc/vlt38jc172b76pd4lmy9ch340000gn/T/grok-goal-a3a70e15315e/implementer}"
BUNDLE="ai.swarm.game"
LOG="$SCRATCH/launch.log"
mkdir -p "$SCRATCH"
: > "$LOG"

xcrun simctl boot "iPhone 17" 2>/dev/null || true

cd "$(dirname "$0")/../ios"
xcodegen generate >/dev/null
xcodebuild -project SWARM.xcodeproj -scheme SWARM -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build >/dev/null

APP=$(find ~/Library/Developer/Xcode/DerivedData -path "*/Build/Products/Debug-iphonesimulator/SWARM.app" -type d 2>/dev/null | head -1)
if [[ -z "$APP" ]]; then
  echo "SWARM.app not found" | tee -a "$LOG"
  exit 1
fi
xcrun simctl install booted "$APP" 2>&1 | tee -a "$LOG"

alive=0
for attempt in 1 2; do
  echo "=== Launch attempt $attempt (SWARM_AUTOSTART immortal QA) ===" | tee -a "$LOG"
  xcrun simctl terminate booted "$BUNDLE" 2>/dev/null || true
  sleep 1
  OUT=$(SWARM_AUTOSTART=1 xcrun simctl launch booted "$BUNDLE" 2>&1) || true
  echo "$OUT" | tee -a "$LOG"
  PID=$(echo "$OUT" | awk -F': ' '/^[a-z]/ {print $2}' | tail -1)
  if [[ -z "$PID" || "$PID" == "$BUNDLE" ]]; then
    PID=$(echo "$OUT" | awk '{print $NF}')
  fi
  sleep 12
  if kill -0 "$PID" 2>/dev/null; then
    echo "alive after 12s attempt $attempt pid=$PID (playerInvulnerable=true)" | tee -a "$LOG"
    alive=$((alive + 1))
  else
    echo "NOT alive attempt $attempt pid=$PID" | tee -a "$LOG"
  fi
done

echo "=== Launch attempt 3 (SWARM_MORTAL_AUTOSTART casual mortal) ===" | tee -a "$LOG"
xcrun simctl terminate booted "$BUNDLE" 2>/dev/null || true
sleep 1
OUT=$(SWARM_MORTAL_AUTOSTART=1 xcrun simctl launch booted "$BUNDLE" 2>&1) || true
echo "$OUT" | tee -a "$LOG"
PID=$(echo "$OUT" | awk -F': ' '/^[a-z]/ {print $2}' | tail -1)
if [[ -z "$PID" || "$PID" == "$BUNDLE" ]]; then
  PID=$(echo "$OUT" | awk '{print $NF}')
fi
sleep 12
if kill -0 "$PID" 2>/dev/null; then
  echo "alive after 12s attempt 3 pid=$PID (playerInvulnerable=false casualAutopilot=true)" | tee -a "$LOG"
  mortal_alive=1
else
  echo "NOT alive attempt 3 pid=$PID" | tee -a "$LOG"
  mortal_alive=0
fi

if [[ "$alive" -lt 2 ]]; then
  echo "FAIL: only $alive/2 immortal launches confirmed alive" | tee -a "$LOG"
  exit 1
fi
if [[ "${mortal_alive:-0}" -lt 1 ]]; then
  echo "FAIL: mortal autostart launch did not stay alive" | tee -a "$LOG"
  exit 1
fi
echo "PASS: immortal QA (2x) + mortal casual (1x) launches alive" | tee -a "$LOG"