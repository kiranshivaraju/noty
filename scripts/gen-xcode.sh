#!/bin/bash
# Regenerates Noty.xcodeproj from project.yml.
#
# The generated project is committed, so this is only needed after editing
# project.yml. XcodeGen is fetched to a temp dir rather than installed, so it
# leaves nothing behind on the machine.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if command -v xcodegen >/dev/null 2>&1; then
    XCODEGEN="$(command -v xcodegen)"
else
    TOOLS="${TMPDIR:-/tmp}/noty-xcodegen"
    XCODEGEN="$TOOLS/xcodegen/bin/xcodegen"
    if [ ! -x "$XCODEGEN" ]; then
        echo "→ fetching XcodeGen"
        mkdir -p "$TOOLS"
        curl -sL -o "$TOOLS/xcodegen.zip" \
            https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip
        unzip -oq "$TOOLS/xcodegen.zip" -d "$TOOLS"
        chmod +x "$XCODEGEN"
        xattr -d com.apple.quarantine "$XCODEGEN" 2>/dev/null || true
    fi
fi

cd "$ROOT"
"$XCODEGEN" generate --spec project.yml
echo "✓ Noty.xcodeproj regenerated"
