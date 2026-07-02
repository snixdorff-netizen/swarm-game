#!/usr/bin/env bash
# Reset sibling repos to clean HEAD — goal scope is Developer/swarm only.
set -euo pipefail

DEVELOPER="$(cd "$(dirname "$0")/../.." && pwd)"
SCRATCH="${GROK_GOAL_SCRATCH:-/var/folders/jc/vlt38jc172b76pd4lmy9ch340000gn/T/grok-goal-ca2d648e3fec/implementer}"
mkdir -p "$SCRATCH"

clean_repo() {
  local name="$1"
  local path="$DEVELOPER/$name"
  [[ -d "$path/.git" ]] || return 0
  git -C "$path" reset --hard HEAD
  git -C "$path" clean -fd
  git -C "$path" status --porcelain
}

{
  echo "=== workspace-clean $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
  echo "chum-jaws-bridge:"
  clean_repo chum-jaws-bridge || true
  echo "wildlife-acoustics-training:"
  clean_repo wildlife-acoustics-training || true
  echo "swarm (unchanged):"
  git -C "$DEVELOPER/swarm" status --porcelain
} | tee "$SCRATCH/workspace-clean.log"

if grep -q '^.' "$SCRATCH/workspace-clean.log" 2>/dev/null; then
  : # porcelain lines only under repo sections — check siblings empty
fi

for sibling in chum-jaws-bridge wildlife-acoustics-training; do
  if [[ -n "$(git -C "$DEVELOPER/$sibling" status --porcelain)" ]]; then
    echo "FAIL: $sibling still dirty after clean" | tee -a "$SCRATCH/workspace-clean.log"
    exit 1
  fi
done

echo "PASS: sibling repos clean" | tee -a "$SCRATCH/workspace-clean.log"