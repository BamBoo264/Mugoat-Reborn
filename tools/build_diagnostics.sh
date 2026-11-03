#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../ios"
xcodegen generate
xcodebuild -project MugoatReborn.xcodeproj -scheme MugoatReborn -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath Build/Derived CODE_SIGNING_ALLOWED=NO build > Build/xcodebuild.log 2>&1 || { tail -100 Build/xcodebuild.log; exit 1; }
mkdir -p Build/Package/Payload
 ditto Build/Derived/Build/Products/Release-iphoneos/MugoatReborn.app Build/Package/Payload/MugoatReborn.app
(cd Build/Package && zip -qry ../../../Mugoat-Reborn-Diagnostics-UNSIGNED.ipa Payload)
echo "Diagnostic import app only. GTA runtime NOT COMPLETED. Needs valid signing before installation."
