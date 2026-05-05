# Repo Cortex Changelog


All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## Related Docs
- [Release State](./RELEASE_STATE.md)
- [v1.0 Release Criteria](./V1_RELEASE_CRITERIA.md)
- [Release Certification Checklist](./RELEASE_CERTIFICATION_CHECKLIST.md)
- [Remaining Work](../implementation/REMAINING_WORK.md)

## [Unreleased]

### Added - Release Remediation (2026-05-04)

- **Governance/GoldenTask execution fixes**: `Invoke-LLMQuery` fully rewritten with `-Offline` simulation mode, real provider resolution via `Resolve-ProviderProfile` when environment variables are configured, and clear error messages when no executor is available and `-Offline` is not used. `Save-GoldenTaskResult` fixed for PS 5.1 compatibility (replaced `ConvertFrom-Json -AsHashtable` with `ConvertFrom-Json` + `ConvertTo-Hashtable`).
- **PS 5.1 compatibility fixes**: `Get-LLMWorkflowPalaces` in module loader fixed to use `ConvertTo-Hashtable` instead of PS 7+ `ConvertFrom-Json -AsHashtable`. `Invoke-ReleaseCertification.ps1` mojibake pattern changed from literal Unicode chars to `[\x80-\xFF]{2,}`.
- **Release certification tightened**: Added `-Strict` mode to `Invoke-ReleaseCertification.ps1` with mojibake detection, stale artifact checks, module export/alias parity validation, build orchestrator existence check, and Pester smoke test presence validation.
- **Release preflight script**: Added `tools/release/test-release-prereqs.ps1` for pre-tag validation — verifies VERSION/manifest/compatibility-lock/changelog agreement, stale artifact absence, build orchestrator presence, module layout, SHA256 generation, and Docker file existence.
- **Module export surface tests**: Added `tests/ModuleExportSurface.Tests.ps1` validating every `FunctionsToExport` and `AliasesToExport` entry resolves at module load time.
- **Golden task execution tests**: Added `tests/GoldenTaskExecution.Tests.ps1` covering default-path errors, offline mode behavior, result persistence, failure recording, and PS 5.1-compatible `ConvertTo-Hashtable` conversion.
- **Build orchestration tests**: Added `tests/BuildOrchestration.Tests.ps1` validating build orchestrator, CI validation, release certification, and security script presence along with VERSION check.

### Changed - Reliability Hardening (2026-04-14)

- Hardened `DoclingAdapter.ps1` failure visibility by replacing silent command/path probes with explicit helper-based resolution and verbose-safe suppressed-exception diagnostics.
- Hardened `GeometryNodesParser.ps1` file path probing by removing `-ErrorAction SilentlyContinue`, adding explicit resolution/error signaling, and covering fallback/error paths with dedicated parser tests.
- Hardened `LLMWorkflow.HealFunctions.ps1` runtime safety by replacing silent probes with explicit helper functions, adding safe workflow-version fallback for history entries, and fixing strict-mode/count edge cases.
- Hardened `LLMWorkflow.Dashboard.ps1` command-probe behavior by replacing silent `Get-Command` checks with explicit safe resolution for `python` and `codemunch-pro`.
