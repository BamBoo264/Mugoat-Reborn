> Updated: the subsequently supplied GTAV-v10.1.ipa resolves the missing native host. See N003_MENYOO_CAMERA.md. The N002 analysis below remains historical.

# Requested Menyoo and vehicle camera integration — blocked by runtime ABI

Target: Reborn N002, based on the user-supplied GTAV-unsigned-2-11.ipa.
Status: NOT INTEGRATED. No replacement IPA was built because bundling unsupported plugins would not make them execute.

## Confirmed package formats

- Menyoo-iOS.asi: PE/Windows x86-64, 6,666,752 bytes. Its manifest targets gamePort 1.4.1 / engine 8b0b5899ed. Imports ScriptHookV.dll, KERNEL32.dll, USER32.dll, SHELL32.dll, WINMM.dll, WININET.dll and WINHTTP.dll. The included installation notes require the old port's ASI/Blink loader.
- DynamicVehicleFirstPerson.asi: PE/Windows x86-64, 1,297,408 bytes. Imports ScriptHookV.dll, KERNEL32.dll, USER32.dll, SHELL32.dll and ole32.dll. MenuKey is NONE by default; its readme uses cheat dfpv. Setting F7 alone does not supply a plugin loader.

## Confirmed target limitations

N002 retains the ARM64 native engine and libgtacompat from the audited IPA. The compatibility library contains the explicit unsupported-script message: %@ is a script mod (Script Hook V, .asi / .dll): those don't run on the %@ yet. Its symbols expose a built-in CMTrainerController / compat_TakeTrainerCommand, but no ScriptHookV plugin entry points or Blink runtime were found in the main executable or compatibility library. The built-in trainer is not a ScriptHookV ABI.

The Foundation localization bootstrap has no game-thread/native dispatch interface. It cannot load Windows machine code or run script natives simply by copying an ASI into Frameworks.

## Required next input/implementation

Use a runtime that supports ScriptHookV/ASI and the required GTAV_IOS dataset, or obtain the native runtime's source and implement its plugin execution/API layer. A different port's advertised ASI support is not proof that this particular IPA supports it or that it accepts the required dataset.

Do not upload the supplied binaries or integrate them as a claimed working feature. Keep the current N002 IPA unchanged until an executable integration can be verified on device.

## Supplied GTAV-ScriptHook-Pack.zip

Inspected the 233-entry archive (42,714,500 uncompressed bytes). Its manifest identifies posthook 3.4, port 2026-11-03. It supplies menyooStuff, managed .NET assemblies and scripts; no Mach-O native library or ASI executable is present. Its README states that the app itself carries the native parts. The README also explicitly says Windows C++ .asi mods cannot run, despite built-in native Menyoo being supported by the matching app. Therefore this resource pack alone neither supplies N002 with a PostHook host nor makes the Windows DynamicVehicleFirstPerson ASI executable. A matching native host/source or the IPA distributed with this pack is still required.
