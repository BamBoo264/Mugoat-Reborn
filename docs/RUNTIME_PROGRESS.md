# Original runtime implementation — 2026-11-03

New authored modules (no runtime binary reused): Swift RPF7 table parser and range reader; explicit nested archive spans; bounded strict raw-DEFLATE C/zlib wrapper; native read-only runtime catalog; demand-first actor scheduler with worker limits, duplicate-request coalescing, byte-budgeted LRU and CPU-cache memory-warning release. Python tooling independently exercises archive layout on the owner's real data. No game data is uploaded for tests.

Real data: 2,343 archive attempts, 209,330 file entries; 59,979 YDR, 16,480 YFT, 13,991 YDD, 32,721 YTD, 10,341 YMAP, 1,945 YTYP, 926 YSC, 4,630 AWC. One nested archive update/update.rpf/dlc_patch/patchday1ng/x64/patch/data/lang/chinesesimp.rpf declares a plaintext table but its root/name offsets do not parse as RPF7; rejected explicitly. Four real metadata payloads were successfully decompressed. These results are structural, not a gameplay test.

Format facts inspected from dexyfex/CodeWalker RpfFile.cs at https://github.com/dexyfex/CodeWalker/blob/master/CodeWalker.Core/GameFiles/RpfFile.cs . No CodeWalker implementation copied; no external code/license presumed. No AES/NG key bundled or encrypted content bypass. zlib is a system dependency; new parser/source uses this repository's MIT license.

Implemented does not mean complete engine: resource placement, skeletal/vehicle physics, YMAP/YTYP semantic decoding, script VM/native functions, shader execution and GTA renderer/audio remain NOT COMPLETED. The catalog button reads actual imported RPFs, not a fake scene. Gameplay PLAY remains gated.

Resource stage: sampled data RSC7 bodies use Zstandard magic 28 B5 2F FD. Four real YMT payloads decoded to exactly 98,304 / 49,152 / 65,536 / 73,728 bytes matching page flags. Added native Zstd + DEFLATE resource decoder and checked 0x50000000/0x60000000 address-segment reader. Uses official Zstandard 1.5.7 decompression/common source only with BSD license; source archive SHA256 is pinned in ios/Vendor/zstd/SOURCE.json.

RuntimeBootstrap now reads and XML-validates gameconfig.xml, handling.meta and gta5.meta through the authored asset store. This proves metadata loading, not world simulation. It does not rewrite metadata or mutate game data.

## Script runtime stage
Authored bounded ScriptProgram loader reconstructs code/string pages, static slots and rotated native hashes with full 64-bit tagged-pointer checks. Authored ScriptMachine executes an explicitly limited instruction subset: scalar integer/float math, constants, simple root frame/local/static slots, conditional/unconditional jumps and explicit native dispatch. Budget exhaustion yields instead of hanging. Unknown opcode/native fails visibly. Function calls, pointer operations, vector opcodes, complete script scheduler and gameplay natives remain NOT COMPLETED. Synthetic tests do not claim mission execution.

Real local data audit: 917 YSC containers loaded; 512,074,762 code bytes; 6,353 distinct native hashes referenced. Nine script entries failed decompression/resource-length checks. No game script bytes or proprietary source uploaded. Format facts inspected at https://github.com/Jaycadox/ysc-utils/blob/master/src/ysc.rs and src/disassemble.rs; no third-party implementation copied or assumed licensed.
