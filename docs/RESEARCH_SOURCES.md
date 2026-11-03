# Research sources — checked 2026-11-03
- Apple Files/document picker: https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller
- Security-scoped access: https://developer.apple.com/documentation/foundation/url/startaccessingsecurityscopedresource()
- File coordination: https://developer.apple.com/documentation/foundation/nsfilecoordinator
- Metal: https://developer.apple.com/documentation/metal
- MetalFX: https://developer.apple.com/documentation/metalfx
- GPU counters: https://developer.apple.com/documentation/metal/counter-sampling
- Memory warnings: https://developer.apple.com/documentation/uikit/uiapplication/didreceivememorywarningnotification
- Lifecycle: https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle
- Existing MIT web-port source: local gta5-ios-port-1.4.4/LICENSE; https://github.com/kevinerikjs/gta5-ios-port (raw README request returned 404; do not depend on current fetch)
- Wasmtime/wgpu runtime reference: https://github.com/c22dev/muguet (GPL-3.0; no code copied)
- WASM2C: https://github.com/WebAssembly/wabt (Apache-2.0)
- DXMT: https://github.com/3Shain/dxmt — exact license/version must be pinned before reuse; public renderer is not the missing compatibility/runtime source
- Vulkan→Metal alternative: https://github.com/KhronosGroup/MoltenVK (Apache-2.0; not itself DirectX or game runtime)

Apple web pages expose JS/Markdown docs; API behavior must also pass SDK compilation and device tests. No source imported solely from a search result. No reliance on unofficial forum performance claims.

- RPF7 format reference inspected, no implementation copied: https://github.com/dexyfex/CodeWalker/blob/master/CodeWalker.Core/GameFiles/RpfFile.cs
- Zstandard official decompressor source, BSD: https://github.com/facebook/zstd/releases/tag/v1.5.7 . Version and downloaded source archive hash recorded in ios/Vendor/zstd/SOURCE.json; LICENSE retained and bundled.
