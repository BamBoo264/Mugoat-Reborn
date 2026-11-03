# Asset audit
Source inspected read-only: E:\GTAV_IOS (development only). 925 files excluding log directory, 21,575,602,334 bytes; 113 RPF, 382 FXC, 391 SPS, one FX, one BIN and metadata/config/report files. Version file: 1.0.231.0.

All files have a local SHA256 baseline; 113 RPF7 header/table-bound checks passed. This establishes reproducible baseline bytes, **not authenticity or full archive contents**. Encryption/compression/semantic validation, exact expected retail completeness, texture correctness and runtime compatibility remain NOT COMPLETED.

Raw archive layout common.rpf/x64[a-w].rpf differs from original Nova's web manifest layout. No game.wasm or native executable found in this dataset. FXC is not Metal-ready merely by being present; native runtime's translator/ABI needed. No conversion applied. Local IPA audit in audit/ is ignored by Git. expected-manifest.json contains only filenames, sizes and hashes, no game bytes. Reports/config files in the first profile are strict snapshot entries; required-versus-optional runtime classification is not yet confirmed.
