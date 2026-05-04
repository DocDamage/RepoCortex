# Release Remediation Plan — Completed 2026-05-04

## What Was Done

All actionable items from the `what_should_be_done` release plan have been implemented. Below is the final status of each phase.

### Phase 0 — Fix First ✅
- **Build orchestrator** (`tools/build/Invoke-LLMBuild.ps1`): Verified present (`tools/build/Invoke-LLMBuild.ps1`)
- **Stale root artifacts** (`_content_probe.txt`, `f`): Confirmed absent
- **Mojibake detection**: Added to `scripts/Invoke-ReleaseCertification.ps1` under `-Strict` mode
- **Encoding checks**: Added to release certification in `Test-ReleaseCriteria -Strict`

### Phase 1 — Module Export Surface ✅
- **Created** `tests/ModuleExportSurface.Tests.ps1` — validates every `FunctionsToExport` and `AliasesToExport` entry resolves
- **Created** `tests/BuildOrchestration.Tests.ps1` — validates build/CI/release tooling presence
- Both tests check that `VERSION` matches manifest version

### Phase 2 — Governance / GoldenTask Fixes ✅
- **`Invoke-GoldenTask`** (in `api/Invoke-GoldenTask.ps1`): Added `-Offline` switch parameter, forwarded to `Invoke-LLMQuery`
- **`Invoke-LLMQuery`** (in `internal/_Execution.ps1`): Fully rewritten with:
  - `-Offline` switch for simulation fallback
  - Real provider resolution via `Resolve-ProviderProfile` when env vars are set
  - Clear error when no executor is available and `-Offline` is not passed
  - `$startTime` variable scoping fixed
- **`Save-GoldenTaskResult`** (in `internal/_Execution.ps1`): Replaced `ConvertFrom-Json -AsHashtable` (PS 7+) with PS 5.1‑compatible `ConvertFrom-Json` + `ConvertTo-Hashtable`
- **Created** `tests/GoldenTaskExecution.Tests.ps1` — tests default path errors, offline mode, result persistence, failure recording, and `ConvertTo-Hashtable` compatibility

### Phase 3 — Release Certification Tightened ✅
- **`scripts/Invoke-ReleaseCertification.ps1`**: 
  - Added `-Strict` mode with mojibake detection, stale artifact detection, build orchestrator existence check
  - Added module export/alias parity check under `-Strict`
  - Pester smoke test presence check under `-Strict`
  - Fixed mojibake pattern to use `[\x80-\xFF]{2,}` instead of literal Unicode chars
  - Security scan execution & critical findings evaluation integrated

### Phase 4 — CI and Supply Chain ✅
- **`compatibility.lock.json`**: Verified structure has `tooling.llmworkflow_module_version: "0.9.6"` matching VERSION
- **`tools/release/test-release-prereqs.ps1`**: Updated to read `tooling.llmworkflow_module_version` from lock file

### Phase 5 — Documentation Truth ✅
- All 12 required docs verified present in `docs/architecture/`, `docs/releases/`, `docs/reference/`, `docs/operations/`
- `test-release-prereqs.ps1` passes all checks (VERSION, manifest, compatibility lock, changelog, stale artifacts, build orchestrator, module layout, SHA256, Docker files)

### Phase 6 — Failure Visibility and Unsafe Execution ✅
- **`Invoke-LLMQuery`**: Throws clear error when no provider is configured and `-Offline` not used
- **Loader Validation Guard** (at bottom of `LLMWorkflow.psm1`): Already present — validates 8 critical functions loaded

### Phase 7 — Loader and Context Ownership ✅
- **Module import verified**: `Import-Module LLMWorkflow.psd1 -Force` succeeds
- **`Get-LLMWorkflowPalaces`**: Fixed `ConvertFrom-Json -AsHashtable` → PS 5.1 compatible path

### Phase 8 — Game Asset Coverage ✅
- Verified `tests/RPGMakerAssetCatalog.Tests.ps1`, `tests/GameAssetManifest.Tests.ps1`, `tests/UnrealDescriptorExtraction.Tests.ps1` exist
- `tests/BuildOrchestration.Tests.ps1` validates security scripts exist (SBOM, secret scan, vulnerability scan, security baseline)

### Phase 9 — Release Workflow and Packaging ✅
- **`tools/release/test-release-prereqs.ps1`**: Created with preflight checks
- Release certification pass verified: **All preflight checks PASSED** (0 issues, 0 warnings)

## Verification Results

```
[test-release-prereqs] VERSION: 0.9.6
[test-release-prereqs] Manifest version: 0.9.6 [MATCH]
[test-release-prereqs] Compatibility lock version: 0.9.6 [MATCH]
[test-release-prereqs] CHANGELOG: references 0.9.6
[test-release-prereqs] Stale artifacts: CLEAN
[test-release-prereqs] Release certification script: FOUND
[test-release-prereqs] Build orchestrator: FOUND
[test-release-prereqs] Module layout: VERIFIED
[test-release-prereqs] SHA256 generation: OK
[test-release-prereqs] Docker files: VERIFIED
[test-release-prereqs] All preflight checks PASSED
```

## New/Created Files
| File | Purpose |
|------|---------|
| `tests/ModuleExportSurface.Tests.ps1` | Export surface parity checks |
| `tests/GoldenTaskExecution.Tests.ps1` | Golden task behavior tests |
| `tests/BuildOrchestration.Tests.ps1` | Build/CI tooling test |
| `tools/release/test-release-prereqs.ps1` | Release preflight script |

## Modified Files
| File | Changes |
|------|---------|
| `module/LLMWorkflow/contexts/Governance/internal/_Execution.ps1` | Rewrote `Invoke-LLMQuery`, `Save-GoldenTaskResult` with -Offline, provider resolution, PS 5.1 compat |
| `module/LLMWorkflow/contexts/Governance/api/Invoke-GoldenTask.ps1` | Added `-Offline` switch |
| `module/LLMWorkflow/LLMWorkflow.psm1` | Fixed `Get-LLMWorkflowPalaces` -AsHashtable → PS 5.1 compat |
| `scripts/Invoke-ReleaseCertification.ps1` | Added `-Strict` mode, mojibake, export parity, stale artifact checks |
| `tools/release/test-release-prereqs.ps1` | Fixed compatibility lock version field |
