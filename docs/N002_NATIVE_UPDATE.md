# Reborn N002 — user-supplied native port update

This updates the local binary base to `GTAV-unsigned-2-11.ipa`. It does not recover or update unavailable GTA engine source. The public repository supplies our packaging/bootstrap source and Vietnamese localization only; original runtime binaries remain local inputs.

Changes:
- Use the newer user IPA, audited main executable SHA256 `45db6e2caadc25db58a4e53bae0ff6c602f5836c6048ce4d9561efc3e2057054`.
- Translate all 800 launcher template entries, including meaningful settings explanations and import errors, preserving formatting parameters. Product names/units are intentionally unchanged. Trainer/game localization is outside this update.
- Remove the old Swift import overlay/button from the compiled module. Use only a small Foundation bootstrap selecting the native Vietnamese language pack at startup and registering it in the documented launcherlang folder.
- Preserve all engine sections, existing native input/render/audio/streaming implementation and original libraries. No per-frame hooks.
- Keep bundle ID `app.bamboo264.reborn.native` so this can update Reborn separately from the original app.

Data: Files > On My iPhone > Mugoat Reborn > GTAV > common.rpf. Copy the data yourself. No duplicate import is required.

## iOS 15 feasibility

The main executable and all five runtime dylibs declare minimum iOS 16.3. `winemetal.dylib` strongly links `/System/Library/Frameworks/MetalFX.framework/MetalFX`; MetalFX is available from iOS 16. Merely changing the plist or Mach-O minimum cannot provide the missing framework. A supported iOS 15 port requires rebuilding/adapting unavailable native runtime/renderer source with API fallbacks. This update therefore retains iOS 16.3, and does not claim iOS 15 support.

Reference: https://developer.apple.com/documentation/MetalFX

## Verification boundaries

Local tests check Mach-O header safety, unchanged engine file sections, removal of import hooks, and localization format strings. GitHub compiles only the authored Foundation dylib. Local composition validates the resulting ZIP, original library byte hashes and bundled translation. Actual iPhone launch, Vietnamese language selection and gameplay remain DEVICE TEST REQUIRED.
