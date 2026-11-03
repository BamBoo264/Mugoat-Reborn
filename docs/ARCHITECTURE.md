# Architecture
Files picker → scoped provider URL → background coordinated reader → chunk SHA256 → app-managed partial directory → verified atomic final directory → runtime adapter.

Launcher owns UI state; importer owns progress/cancellation; immutable manifest owns paths, lengths and baseline hashes. Runtime adapter must independently approve data version. Data READY does not enable PLAY unless the runtime is available and compatible. No Windows path is embedded in app source.

The initial implementation selects app-managed storage. Provider scope ends after import. No external bookmark is relied on for gameplay. Re-selecting the same source resumes verified partial files; no source file is removed. Import space must be sufficient for remaining files plus safety margin. A completed managed import is revalidated without another copy. Automatic cheap startup validation/index-cache and deletion UI are NOT COMPLETED.
