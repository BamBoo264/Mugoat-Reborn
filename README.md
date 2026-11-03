# Mugoat Reborn

## Current native integration branch (N002)

`native-runtime-bridge` locally composes a user-supplied native IPA with an authored Vietnamese-language bootstrap. It is **not** recovered GTA engine source. The source-only GitHub workflow never receives the original IPA or game data. See [N002 changes and iOS requirements](docs/N002_NATIVE_UPDATE.md).

The old import overlay is removed in N002. Copy your data to Files > On My iPhone > Mugoat Reborn > GTAV (common.rpf directly inside), then restart. Minimum iOS remains 16.3; actual device launch and localization must be verified.

Build the manual `native-bridge.yml` workflow on this branch, download its two authored files, then compose locally:

```powershell
python tools/package_native_bridge.py --source "E:\GTAV-unsigned-2-11.ipa" --bridge libRebornBridge.dylib --localization launcher_vi.json --output Mugoat-Reborn-N002-UNSIGNED.ipa
```

Re-sign all app/framework code using your own valid certificate/profile. The original port executable and runtime libraries remain private inputs, not public source.

## Earlier independent diagnostic project

Fresh native iOS launcher/import architecture. **This is not yet a playable GTA V port. Runtime, rendering, controls and device benchmarks are NOT COMPLETED.**

1. Clone this repository on an Apple Silicon Mac.
2. Install Xcode, Python 3 and xcodegen.
3. Run tests and `bash tools/build_diagnostics.sh` to build the unsigned diagnostic IPA.
4. Sign/provision it for your iPhone; unsigned does not mean installable.
5. Download your own matching GTA V data onto your iPhone.
6. Open the diagnostic launcher.
7. Press **IMPORT GTA V GAME DATA** and select the game folder through Files.
8. Wait for SHA256 validation and managed import. No external provider URL is assumed permanent; insufficient storage stops the copy.
9. Data READY means verified import only. PLAY is disabled until a compatible, reproducible runtime is integrated and tested.

No proprietary game bytes are in this repository. `expected-manifest.json` is metadata from the owner's audited snapshot, not proof of gameplay compatibility. Existing data and Nova were not modified.

See [feasibility](docs/FEASIBILITY_REPORT.md), [audit](docs/ASSET_AUDIT.md), [import design](docs/DATA_IMPORT_DESIGN.md), [build instructions](docs/BUILD_IOS.md), [known issues](docs/KNOWN_ISSUES.md).
