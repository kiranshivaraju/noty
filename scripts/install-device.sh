#!/bin/bash
# Builds, signs and installs Noty on a connected iPhone.
#
#   ./scripts/install-device.sh          first connected device
#   ./scripts/install-device.sh <udid>   a specific one
#
# Free personal-team provisioning expires after seven days, at which point the
# installed app stops launching. Re-running this re-signs and reinstalls over the
# top, which keeps the app's container — and so the notes in it. Deleting the app
# from the Home Screen does NOT keep them: there is no sync and no second copy.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUNDLE_ID="com.kiranshivaraju.noty"

if [ $# -ge 1 ]; then
    UDID="$1"
else
    UDID="$(xcodebuild -project Noty.xcodeproj -scheme Noty -showdestinations 2>/dev/null \
            | grep 'platform:iOS,' | grep -v 'placeholder' \
            | head -1 | sed -E 's/.*id:([0-9A-Za-z-]+).*/\1/')"
fi

if [ -z "${UDID:-}" ]; then
    echo "no connected iPhone found — plug one in or join it to the same network" >&2
    exit 1
fi

echo "→ building for $UDID"
xcodebuild -project Noty.xcodeproj -scheme Noty \
    -destination "platform=iOS,id=$UDID" \
    -allowProvisioningUpdates \
    -quiet build

APP="$(xcodebuild -project Noty.xcodeproj -scheme Noty \
       -destination "platform=iOS,id=$UDID" -showBuildSettings 2>/dev/null \
       | awk -F' = ' '/ BUILT_PRODUCTS_DIR/ {print $2; exit}')/Noty.app"

[ -d "$APP" ] || { echo "built app not found at $APP" >&2; exit 1; }

echo "→ installing $APP"
xcrun devicectl device install app --device "$UDID" "$APP"

echo "→ launching"
xcrun devicectl device process launch --device "$UDID" "$BUNDLE_ID" || cat <<'EOF'

The app is installed but iOS refused to launch it. On a first install with free
provisioning this is expected — trust the certificate on the phone:

  Settings → General → VPN & Device Management → Developer App
    → Apple Development: <your Apple ID> → Trust

Then run this script again, or just tap the icon.
EOF
