#!/bin/bash
# Launches HandyBar, lets it settle with the panel closed, and reports idle
# memory footprint, CPU, and idle wakeups. Results vary by machine; compare
# against the baseline in CONTRIBUTING.md on the same Mac.
#
# Usage: scripts/measure-idle.sh [path/to/HandyBar.app]
#   SETTLE_SECONDS  Wait before measuring (default 10).
#   SAMPLE_SECONDS  CPU and wakeup sampling interval (default 10).
set -euo pipefail

cd "$(dirname "$0")/.."
app="${1:-build/DerivedData/Build/Products/Release/HandyBar.app}"
settle="${SETTLE_SECONDS:-10}"
sample="${SAMPLE_SECONDS:-10}"
binary="$app/Contents/MacOS/HandyBar"

if [[ ! -x "$binary" ]]; then
    echo "error: $binary not found; run scripts/build-dmg.sh first or pass an app path" >&2
    exit 1
fi
if pgrep -x HandyBar >/dev/null; then
    echo "error: HandyBar is already running; quit it first" >&2
    exit 1
fi

"$binary" >/dev/null 2>&1 &
pid=$!
trap 'kill "$pid" 2>/dev/null || true' EXIT

sleep "$settle"
footprint="$(footprint "$pid" | sed -nE 's/.*Footprint: ([0-9.]+ [KMG]?B).*/\1/p' | head -1)"
read -r cpu wakeups < <(top -l 2 -s "$sample" -pid "$pid" -stats cpu,idlew | tail -1)

echo "app:            $app"
echo "footprint:      $footprint"
echo "cpu:            $cpu%  (over ${sample}s)"
echo "idle wakeups:   $wakeups  (top IDLEW)"
