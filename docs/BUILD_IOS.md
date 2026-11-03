# Build iOS
Apple Silicon Mac, Xcode with iPhone SDK, xcodegen and Python 3 required. Windows cannot run Xcode. Run `python3 -m unittest discover -s tests -v`, then `bash tools/build_diagnostics.sh`.
Output: Mugoat-Reborn-Diagnostics-UNSIGNED.ipa, an import-validation app with PLAY disabled. Install only after valid provisioning/signing; unsigned/ad-hoc packaging is not an Apple-trusted signature. Actual extended-memory grant depends on device, provisioning and entitlements, not a RAM number in settings.

Playable build instructions: NOT COMPLETED until runtime source/toolchain/compatible data contract are available. No game assets expected inside this IPA.
