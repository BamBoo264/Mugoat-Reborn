# Public source and release rules
Target account BamBoo264 confirmed through existing Git Credential Manager; GitHub CLI not installed. Use authenticated API/Git helper without logging secrets.

Source whitelist: authored Swift/Python/build files, tests, docs, baseline manifest metadata. Exclude RPF, WASM, GTA5 executable, dylibs extracted from supplied IPAs, user logs/saves, compiled shaders and tokens. Diagnostic CI artifacts labelled NOT-GAME. No playable release tag until completion criteria and actual device benchmarks pass. CI runner minutes are account-limited.
