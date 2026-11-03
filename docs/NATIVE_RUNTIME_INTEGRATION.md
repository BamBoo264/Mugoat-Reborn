> Historical N001 design. For the current localization-only N002 module, see [N002_NATIVE_UPDATE.md](N002_NATIVE_UPDATE.md). The importer described below is no longer injected into the native app.

# Native runtime integration â€” experimental, NOT COMPLETED

The required `E:\GTAV_IOS` dataset uses a native archive layout. The Nova WASM runtime is not a compatible substitute. The independent script core in this repository is partial and cannot run GTA V gameplay.

The two user-supplied IPAs contain iOS ARM64 executables and a native DXMT compatibility layer. Their launcher class is `MPLauncherViewController`; the compatibility library contains `/Documents/GTAV`. These facts support an integration experiment, not a proof that every asset or patch matches.

## Source and provenance

This repository owns the new importer/bridge source. It does **not** contain, implement or license the original GTA engine. A complete source-only engine rebuild is NOT COMPLETED. Original IPA binaries remain private local build inputs. No game data or extracted runtime is uploaded by the workflow.

The manual `native-bridge.yml` workflow builds only our dylib and the hash manifest. On Windows, use `tools/package_native_bridge.py` with the original local IPA, compiled bridge, manifest and a new output path. It accepts only the two audited executable hashes, refuses unsafe ZIP paths, overwrites, encrypted executables and insufficient header padding, and checks every file-backed Mach-O section remains byte-identical. Adding a load command invalidates the original signature; output is **unsigned** and must be re-signed with a compatible provisioning profile. Entitlements are not granted by this tool.

## Import behavior

The original native launcher gets an import button. No frame loop, rendering, memory budget, audio or game script changes. Import uses the existing checked, resumable, SHA256-based managed importer, then renames the verified folder to Documents/GTAV without a second copy. Existing Documents/GTAV is never replaced. Restart is required. Additional native decryption patches may be required by the original runtime; data validation does not prove gameplay compatibility.

## Pending device verification

- Button position and native launcher interaction.
- Files provider import, interrupted import, storage failure and relaunch.
- Runtime data/patch matching and actual world loading.
- Controls, sound, missions, memory and 20â€“30 minute frame-time benchmarks.

Do not describe this integration as a new fully authored GTA engine, a tested playable IPA or a performance improvement before device tests.

## Concrete log match

The unmodified executable in `GTAV-unsigned.ipa` has UUID `9BC06659-A6CC-3470-9F22-8990D13ACC9D`, exactly matching `E:\GTAV_IOS\log\run.log`. This is stronger compatibility evidence than the v8 input. The log reports already-decrypted data and normal archive loading without external decryption patches. The preferred test package therefore uses the unsigned input. The fixed manifest excludes four generated root diagnostics; game asset hashes remain mandatory.

The composed app uses bundle ID `app.bamboo264.reborn.native` and display name Mugoat Reborn, keeping it separate from the original port installation. ESign must re-sign all nested code; the composer grants no additional memory entitlement.
