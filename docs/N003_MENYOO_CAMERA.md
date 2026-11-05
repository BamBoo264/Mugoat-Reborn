# Reborn N003 — native ScriptHook/Menyoo and experimental vehicle camera

Base input: user-supplied GTAV-v10.1.ipa. Its native main executable SHA256 is 19da9e98b57e9d84e9651801c4f2736f8d9d727fa4a57949353dc56cc21aa9eb. Unlike N002, it contains ScriptHookV.dylib, Menyoo.shv.dylib, Mono and the native .NET support libraries. Its loader identifies posthook 3.4 and loads .shv.dylib modules. It still uses Documents/GTAV. Actual dataset/gameplay compatibility needs an iPhone test.

## Install and use

- Re-sign all app/framework code with ESign. Keep the Reborn bundle ID to update an existing Reborn installation; do not delete the app/data.
- Place the game data at Files > On My iPhone > Mugoat Reborn > GTAV (common.rpf directly inside).
- On first launcher appearance with data present, the source bootstrap provisions the supplied ScriptHook resource pack into GTAV/mods/scripthook. Copying runs off the UI thread into a staging folder then atomically renames it. Existing scripthook folders and user settings are preserved. If that folder already contains a different/incomplete pack, use the native Mods page to manage it manually.
- After the completion message, fully close/reopen the app once so the native loader discovers the new pack.
- In game open the native trainer > Add-ons > Menyoo. Native Menyoo also accepts F8 or RB + D-pad left. The old Menyoo-iOS.asi is not installed alongside the native Menyoo.
- On the Add-ons page, the Camera navigation button opens the authored camera settings. Enable it, choose first-person in a vehicle, and adjust FOV 65–110, forward offset -0.10–0.50 m, vertical offset -0.15–0.25 m. Camera remains disabled until the user enables it. These are experimental native camera features, not the Windows DynamicVehicleFirstPerson ASI.

## Behavior and boundaries

The camera script calls ScriptHookV natives only on its registered game script, never the UIKit thread. GUI changes pass through atomics. The policy rejects on-foot, third-person, dead, cutscene, no-player-control, paused, faded, switching-character and shooting/aiming states. It releases its own camera and preserves a mission camera that has taken over. No entity textures are removed. It does no per-frame work when disabled (250 ms scheduler sleep).

All original runtime dylibs are copied byte-for-byte. No rendering/streaming/audio performance tweaks are added. MetalShade keeps its supplied default-off policy. .NET availability and low-RAM handling remain the host's own. This does not guarantee no performance impact from enabling plugins or camera effects.

The package and original runtime binaries are local-only build inputs. The public workflow compiles only the authored bootstrap, resource installer and camera plugin. It uses a declaration-only ScriptHook ABI stub; no original binary is uploaded. Existing license files from the resource pack are retained locally in the IPA.

## Verification

- Python composer/header and localization checks.
- macOS Foundation tests of production installer: complete copy, source unchanged, existing settings preserved, missing files rejected, invalid destination rejected and no leftover staging directory after a successful install.
- Camera policy tests covering each excluded state and invalid/extreme FOV values.
- ARM64 compiler/linker build, native ScriptHook imports and safe local IPA composition.
- Pending: actual iPhone startup, Menyoo display/navigation, camera script registration, vehicle touch rotation, mission transitions and 20-minute stability/FPS test.

Native hash/signature reference: https://github.com/alloc8or/gta5-nativedb-data (data facts only; no implementation copied). Names were also verified in the supplied ScriptHook host's native list.
