# Post-Certification Hardening Backlog

This document tracks practical hardening work that remains useful after the 2026-05-04 release certification pass.

It is intentionally narrower than the strategic plan and more execution-oriented than the audit.
Use it to answer one question:

**What should keep improving after the release gates are green?**

**Last Updated:** 2026-05-04

## Related Docs
- [Post-0.9.6 Strategic Execution Plan](./LLMWorkflow_Post_0.9.6_Strategic_Execution_Plan.md)
- [Implementation Progress](./PROGRESS.md)
- [Production Release Audit](../../../AAA_PRODUCTION_RELEASE_AUDIT_2026-05-03.md)

---

## Current Read

The platform is no longer blocked on missing core capability, and the 2026-05-04 certification pass means the tracked release gates are green.
The remaining items below are not reopened blockers; they are the hardening backlog that keeps the release honest as the codebase evolves.

The repo already has broad surface area across:
- orchestration and workflow runtime
- extraction and mixed-artifact handling
- governance and review flows
- MCP and retrieval infrastructure
- game-engine and asset-facing tooling

That breadth is now a strength and a maintenance risk at the same time.
The remaining work is mostly about preserving operational trust after release certification.

### What Recently Improved

Several important cleanup and foundation tasks are already done or materially underway:
- **Release remediation completed (2026-05-04)**: All 9 phases implemented — Governance/GoldenTask execution fixes, PS 5.1 compatibility, release certification tightened with `-Strict` mode, new export surface/golden task/build orchestration tests, release preflight script (`tools/release/test-release-prereqs.ps1`), and remediation report produced (`what_should_be_done_release_plan_2026-05-04.md`)
- **`Invoke-LLMQuery` rewritten**: `-Offline` simulation mode added, real provider resolution via `Resolve-ProviderProfile` when env vars are set, clear error when no executor available
- **`Save-GoldenTaskResult` fixed**: PS 5.1 compatibility — `ConvertFrom-Json -AsHashtable` replaced with `ConvertFrom-Json` + `ConvertTo-Hashtable`
- **`Get-LLMWorkflowPalaces` fixed**: PS 5.1 compatibility in module loader (same `-AsHashtable` fix)
- **Release certification hardened**: `-Strict` mode with mojibake detection, stale artifact checks, module export/alias parity validation, build orchestrator existence check, Pester smoke test validation
- **Release preflight automation**: `tools/release/test-release-prereqs.ps1` verifies VERSION/manifest/lock/changelog agreement (0 issues, 0 warnings)
- explicit module exports replaced wildcard export behavior in `LLMWorkflow.psd1`
- subsystem fork consolidation reduced parallel implementations and loader ambiguity
- CI-safe Pester invocation and core suite stabilization landed
- release/docs truth improved and path drift was reduced

- PowerShell 5.1 compatibility improved in key pack and test paths
- game-asset intake foundations landed for engine-aware manifests and preset scaffolding
- Unreal descriptor extraction landed for `.uplugin` and `.uproject`
- RPG Maker asset catalog parsing landed for common asset families and plugin metadata
- recent asset-ingestion additions shipped with regression tests instead of relying on later cleanup
- 6 Primitive test suites hardened for Pester v5 and PS 5.1
- docs-truth validator restored to green; README/PROGRESS/CHANGELOG metrics aligned
- security baseline scope bug fixed, false positives eliminated, and gate now passes `-FailOnCritical` cleanly
- `GoldenTasks.ps1` decomposed into `contexts/Governance/` (26 files, max 293 lines) with legacy shim preservation
- module loader PSScriptRoot corruption fixed; context loader now uses `$script:ModuleRoot`
- version fragmentation fully resolved (all remaining `0.2.0` references eliminated)
- **Module contract remediation**: Explicit exports in `LLMWorkflow.psd1` fixed to include missing palace commands.
- **Retrieval realism**: Mock-backed adapters replaced with real Qdrant (REST) and functional LanceDB (file) implementations.
- **Provider support consistency**: Universal `claude` and `ollama` support verified across all entry points.
- **MemPalace bridge stability**: Fixed `errno` import defect in the bridge sidecar.
- **v1.0 Release Certification**: Achieved 100% pass rate across all 12 certification categories.

That is real progress.
It also means the remaining work is now less about expansion and more about hardening the surfaces that already exist.

---

## Hardening Backlog by Release Priority

### Priority 0: Failure Visibility and Unsafe Execution

Status: `Release-gate remediated and enforced for critical files`

This was the most important pre-certification work. The 2026-05-04 remediation moved the tracked release risk to green, especially in dashboard, healing, Docling, and parser probe paths. The release certification suite now also blocks unjustified `-ErrorAction SilentlyContinue` usage in release-critical files, including durable execution and MCP lifecycle paths.

#### Ongoing Cleanup
- reduce and justify `-ErrorAction SilentlyContinue` usage in production modules
- eliminate empty `catch` blocks and replace them with explicit handling or rethrow behavior
- remove or tightly isolate `Invoke-Expression` usage from release-relevant paths
- replace `Write-Host` in reusable modules with structured diagnostics or pipeline-safe output
- make degraded-mode behavior visible and testable instead of quiet

#### First Targets
- `GoldenTasks.ps1`
- `GeometryNodesParser.ps1`
- `DoclingAdapter.ps1`
- `ExternalIngestion.ps1`
- `DashboardViews.ps1`
- `LLMWorkflow.HealFunctions.ps1`
- `MLModelDeploymentPipeline.ps1`
- `LLMWorkflow.Dashboard.ps1`

#### Exit Condition
- release-critical modules no longer swallow failures or hide important state transitions from operators and tests, and certification prevents regression in the tracked critical-file set

### Priority 1: Structural Refactoring and Canonical Ownership

Status: `Materially improved; ongoing maintainability work`

The major public-contract and loader ambiguity has been remediated. The repo still contains large modules and some duplicated helper patterns, which should be reduced over time to keep review and regression radius manageable.

#### Ongoing Cleanup
- decompose the largest modules into coherent private helper files or submodules
- replace duplicated utility functions with canonical shared implementations
- make ownership boundaries clearer in file layout and loader wiring
- pin new seams with tests so refactors reduce risk instead of redistributing it

#### First Targets
- `MLModelDeploymentPipeline.ps1`
- `ExternalIngestion.ps1`
- `AIGenerationPipeline.ps1`
- `GoldenTasks.ps1`
- `ExtractionPipeline.ps1`
- `LLMWorkflow.GameFunctions.ps1`
- `IncidentBundle.ps1`
- `Journal.ps1`

#### Exit Condition
- the highest-risk modules are no longer giant, ambiguous maintenance zones

### Priority 2: Module Contracts and PowerShell Hygiene

Status: `Release-gate remediated; continue quality ratcheting`

Explicit exports replaced wildcard exposure, and release certification now checks key contract surfaces. Remaining contract hygiene should be treated as a ratchet: improve modules as they are touched.

#### Ongoing Cleanup
- add `Set-StrictMode` to reusable modules that still lack it
- add `[CmdletBinding()]` where functions are still script-style without proper contracts
- add `.SYNOPSIS` help to public and important semi-public functions
- add `[OutputType()]` where it clarifies downstream behavior
- remediate unapproved PowerShell verbs or document intentional exceptions
- tighten parameter contracts where `$args` is still standing in for explicit parameters

#### First Targets
- `AIGenerationPipeline.ps1`
- `LLMWorkflow.psm1`
- `LLMWorkflow.GameFunctions.ps1`
- `NaturalLanguageConfig.ps1`
- `DashboardViews.ps1`
- `bootstrap-llm-workflow.ps1`
- `UnrealDescriptorParser.ps1`
- `RPGMakerAssetCatalogParser.ps1`
- `SpriteSheetParser.ps1`
- `AtlasMetadataParser.ps1`

#### Exit Condition
- core public surfaces look and behave like deliberate modules, not leftover prototype scripts

### Priority 3: Test and Evidence Coverage

Status: `Certification-covered; broaden as risk changes`

The release certification suite is passing. Additional coverage remains valuable where foundational behavior changes or new public surfaces are added.

#### Ongoing Cleanup
- convert release-critical suites into explicit CI gates
- add direct tests or strong evidence of coverage for state, locking, contract, and workspace primitives
- add more negative and regression tests around exports, loader behavior, and policy fallback paths
- keep newer game-asset and extraction surfaces under regression coverage as they grow
- reduce noisy warnings in suites where signal is still diluted

#### First Targets
- `AtomicWrite.ps1`
- `CommandContract.ps1`
- `FileLock.ps1`
- `Journal.ps1`
- `StateFile.ps1`
- `TypeConverters.ps1`
- `Workspace.ps1`
- `LLMWorkflow.GameFunctions.ps1`
- module export and loader boundary tests

#### Exit Condition
- CI reflects real release risk rather than partial confidence from ad hoc suite runs

### Priority 4: Documentation and Release Truth

Status: `Active release infrastructure`

Documentation truth is now part of release discipline. Keep it aligned as head changes so planning docs do not accidentally read like current blockers after remediation has landed.

#### Ongoing Cleanup
- remove remaining version-label and release-state drift in top-level docs and dashboards
- keep docs-truth checks active and expand them where they add real signal
- standardize `released` versus `documented-head` wording across release-facing docs
- keep plan, progress, changelog, and audit language aligned as head changes

#### Exit Condition
- release docs, automation, and summary dashboards all describe the same reality

### Priority 5: Observability and Policy on the Critical Path

Status: `Gated architecture present; deepen runtime enforcement over time`

The architecture and release gates exist. The ongoing work is to make the signal more useful in real incidents and mutation paths.

#### Ongoing Cleanup
- propagate trace and correlation IDs across routing, retrieval, arbitration, confidence, evidence, extraction, and MCP flows
- make parser and tool failures diagnosable without log archaeology
- ensure policy is invoked at real mutation and exposure boundaries, not just represented on disk
- standardize human-readable allow or deny explanations
- make fallback and degraded policy behavior explicit and testable

#### First Targets
- `QueryRouter.ps1`
- `AnswerPlan.ps1`
- `CrossPackArbitration.ps1`
- `ConfidencePolicy.ps1`
- `EvidencePolicy.ps1`
- `RetrievalCache.ps1`
- MCP gateway and toolkit paths
- extraction failure paths

#### Exit Condition
- a real answer or ingestion incident can be traced and explained end-to-end

### Priority 6: Mixed Artifact and Game Asset Ingestion Hardening

Status: `Capability present and tested; continue real-corpus hardening`

This area is now a real platform capability, not a speculative future add-on. Future work should focus on broader samples, provenance consistency, and honest scope boundaries.

#### Ongoing Cleanup
- keep provenance and license fields consistent across asset and document outputs
- clearly distinguish inventory-only support from deep extraction support for engine-native formats
- normalize marketplace and source-attribution metadata for external assets, including Epic or Fab-style sources
- continue broadening engine-aware coverage without overclaiming binary parsing support
- add stronger help, contracts, and pipeline integration around newer parser surfaces
- validate outputs across more real sample corpora, not only synthetic tests

#### First Targets
- `LLMWorkflow.GameFunctions.ps1`
- `ExtractionPipeline.ps1`
- `UnrealDescriptorParser.ps1`
- `RPGMakerAssetCatalogParser.ps1`
- `SpriteSheetParser.ps1`
- `AtlasMetadataParser.ps1`
- provenance and manifest normalization paths

#### Exit Condition
- mixed-artifact outputs are consistent enough for governance, retrieval, and cataloging without parser-specific special casing

### Priority 7: Security, Portability, and Promotion Discipline

Status: `Certification-covered; keep evidence fresh`

The repo has security and supply-chain pieces in place. The ongoing discipline is making current evidence normal for promotion and keeping portability assumptions visible.

#### Ongoing Cleanup
- triage heuristic secret findings to closure
- remove or normalize hardcoded absolute paths where they affect portability or release tooling
- make security scans and SBOM evidence part of normal promotion flow
- define evidence retention and override rules for release and hotfix scenarios
- keep scratch and audit tooling from leaking local-machine assumptions into production paths

#### First Targets
- `LLMWorkflow.HealFunctions.ps1`
- `NaturalLanguageConfig.ps1`
- `entrypoint.ps1`
- deployment scripts for MCP surfaces
- security promotion scripts and evidence paths
- scratch and audit helpers with absolute path assumptions

#### Exit Condition
- a release candidate cannot move forward without current security evidence and portable-enough execution paths

### Priority 8: Durable Execution and MCP Lifecycle Governance

Status: `Certification-covered; continue enforcement depth`

These are represented in the release gates. Future work should deepen default adoption and lifecycle enforcement.

#### Ongoing Cleanup
- define which long-running workflows must use durability by default
- document and test resume semantics in production-shaped scenarios
- enforce MCP lifecycle transitions rather than just documenting them
- wire tool exposure policy into onboarding, promotion, and retirement flows
- govern retrieval backend selection across environments and profiles

#### Exit Condition
- long-running workflows recover predictably and MCP growth is governed by rules instead of convention

---

## Resolved or Mostly Resolved Items

These are no longer the main remaining-work drivers and should not keep reappearing as if they were still open program blockers.

### Reconcile the Shipped Module with the Codebase
- Status: `Completed`
- explicit exports replaced wildcard export behavior
- loader sourcing was corrected to match canonical components

### Retrieval Realism and Module Contracts
- Status: `Completed` (2026-05-04)
- Mock-backed adapters replaced with functional REST and file-based implementations.
- Manifest exports aligned with documented public surfaces.

### Collapse Parallel Subsystem Forks
- Status: `Completed` or materially resolved for current head
- redundant implementations across major subsystem areas were merged into canonical modules
- remaining work is now about structural quality and governance, not basic fork cleanup

---

## Suggested Execution Order

If we follow one practical sequence after the certification pass, it should be this:

1. Maintain 100% pass rate on `Invoke-ReleaseCertification.ps1`
2. Finalize version bump to `v1.0.0`
3. Complete final merge to `main` and tag the release
4. Transition to operational maintenance

This order matches the new audit on purpose.
It is meant to reduce disagreement between planning docs.

---

## What Counts as Done for Release

For the current branch, release readiness is determined by:
- 100% pass rate from `Invoke-ReleaseCertification.ps1`
- green release preflight checks
- aligned `README.md`, `VERSION`, module manifest, release state, changelog, and certification checklist
- current security and certification evidence generated during promotion
- release-owner sign-off

The backlog above should not be read as evidence that the branch is unfinished. It is the maintenance queue that keeps the platform from drifting after certification.

---

## Basis for This Document

This summary is derived from:
- `docs/implementation/LLMWorkflow_Post_0.9.6_Strategic_Execution_Plan.md`
- `PROGRESS.md`
- `deep_audit_results.txt`
- current release and architecture documents under `docs/`

