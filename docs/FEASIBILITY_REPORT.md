# Feasibility / decision record
| Approach | Evidence and purpose | Compatibility / cost | Decision |
|---|---|---|---|
| Reuse original WASM2C + direct Metal host | Locally available MIT 1.4.4 source, previously built for Nova | Requires exact game.wasm and matching web-data layout. Current archive dataset differs. Engine translated from user code at build time; no engine source license supplied | Do not silently substitute this data/runtime |
| Wasmtime AOT + wgpu | c22dev/muguet source GPL-3.0 | Requires web engine/data; GPL obligations and separate renderer. Does not solve current data incompatibility | Research reference, no code copied |
| Native ARM64 GTA5 + libgtacompat + DXMT | Both user IPAs contain ARM64 MH_EXECUTE GTA5; native dylibs. Log identifies macport | App source and compatibility layer source missing. Engine binaries are not open source; cannot reproduce executable from assets | Integration blocked pending reproducible runtime inputs/adapter; binaries remain local |
| Rewrite GTA V gameplay/engine from asset files | Assets do not contain a compilable engine or all gameplay code | No defensible near-term complete implementation; a scene viewer would not meet requirements | Not represented as a working port |
| Generic DX11→Metal via DXMT | Public source exists | Renderer alone provides neither GTA engine nor Win32/ABI bridge. Exact bundled DXMT commit/license must be established | Do not copy binaries to public repo |

Two IPAs are evidence for runtime architecture, not engine source. Creating a public, fully reproducible playable port from them alone is NOT COMPLETED. Clean launcher/import can proceed independently. No assertion that raw RPF data can boot Nova unchanged.
