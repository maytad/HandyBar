#!/bin/bash
# Fails if a feature target imports a UI framework or another feature target.
# Package.swift cannot enforce this: system frameworks are importable from any
# target, and undeclared sibling modules can resolve from shared build products.
set -euo pipefail

cd "$(dirname "$0")/.."
sources="Packages/HandyBarKit/Sources"
features=(HandyBarAlarm HandyBarAutoClick HandyBarCleanup)
forbidden="SwiftUI|AppKit|Cocoa|HandyBar[A-Za-z]*"

status=0
for feature in "${features[@]}"; do
    dir="$sources/$feature"
    if [[ ! -d "$dir" ]]; then
        echo "error: missing feature target directory $dir" >&2
        status=1
        continue
    fi
    pattern="^[[:space:]]*(@[A-Za-z_]+(\([^)]*\))?[[:space:]]+)*import[[:space:]]+((typealias|struct|class|enum|protocol|let|var|func)[[:space:]]+)?($forbidden)([^A-Za-z0-9_]|$)"
    while IFS= read -r match; do
        [[ -z "$match" ]] && continue
        echo "error: $feature must not import UI frameworks or other feature targets: $match" >&2
        status=1
    done < <(grep -rnE --include='*.swift' "$pattern" "$dir" || true)
done

if [[ $status -eq 0 ]]; then
    echo "Feature target imports OK."
fi
exit $status
