# Mugoat Reborn

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
