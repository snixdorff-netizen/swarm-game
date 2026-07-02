#!/usr/bin/env bash
# Run PractitionerUplift XCTest and emit measured uplift JSON to SCRATCH.
set -euo pipefail

SCRATCH="${GROK_GOAL_SCRATCH:-/var/folders/jc/vlt38jc172b76pd4lmy9ch340000gn/T/grok-goal-ca2d648e3fec/implementer}"
mkdir -p "$SCRATCH"

cd "$(dirname "$0")/../ios"
xcodegen generate >/dev/null

OUT="$SCRATCH/uplift-test.log"
xcodebuild test -project SWARM.xcodeproj -scheme SWARM -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SWARMTests/PractitionerUpliftTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$OUT"

if ! grep -q 'TEST SUCCEEDED' "$OUT"; then
  echo "FAIL: PractitionerUpliftTests did not succeed" | tee "$SCRATCH/uplift-report-fail.txt"
  exit 1
fi

JSON_LINE=$(grep 'UPLIFT_REPORT_JSON:' "$OUT" | tail -1 | sed 's/.*UPLIFT_REPORT_JSON://')
if [[ -z "$JSON_LINE" ]]; then
  echo "FAIL: no UPLIFT_REPORT_JSON in test output" | tee "$SCRATCH/uplift-report-fail.txt"
  exit 1
fi
{
  echo "SWARM PractitionerUplift — measured workflow fidelity"
  echo "source: PractitionerUpliftEngine.computeUpliftReport()"
  echo "xctest: TEST SUCCEEDED"
  echo "json:"
  echo "$JSON_LINE" | python3 -m json.tool 2>/dev/null || echo "$JSON_LINE"
} | tee "$SCRATCH/uplift-report.txt"
echo "$JSON_LINE" > "$SCRATCH/uplift-report.json"

# Scope manifest — swarm repo only (excludes sibling workspace dirs).
cd "$(dirname "$0")/.."
git diff --name-only HEAD~6..HEAD > "$SCRATCH/changed-files-swarm-only.txt"
{
  echo "=== SWARM scope manifest (goal work only) ==="
  echo "repo: $(pwd)"
  echo "excluded: chum-jaws-bridge, wildlife-acoustics-training (sibling dirs, not in swarm commits)"
  echo "--- changed files (last 6 commits) ---"
  cat "$SCRATCH/changed-files-swarm-only.txt"
} | tee "$SCRATCH/scope-manifest.txt"

echo "Wrote $SCRATCH/uplift-report.txt and $SCRATCH/scope-manifest.txt"