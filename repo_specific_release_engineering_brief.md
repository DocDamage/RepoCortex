# Repo-Specific Release Engineering Brief

Repository: `DocDamage/CodeMunch-ContextLattice-MemPalace---All-in-one`  
Target branch: `ci-fixes-attempt`  
Primary product: `LLMWorkflow`, a PowerShell 5.1+ module and release/tooling platform for CodeMunch, ContextLattice, and MemPalace workflows.

## Mission

Take this repository from its current branch state to a truthful, CI-green, release-candidate state.

Do not treat this as a generic app with screens, web routes, React components, or gameplay UI unless code explicitly exposes those surfaces. The real release surfaces are:

- PowerShell module import/export behavior
- Manifest-declared public functions and aliases
- CLI/operator commands
- dashboard commands
- self-healing commands
- plugin and palace management commands
- game-team preset and asset-manifest commands
- ingestion, extraction, retrieval, governance, telemetry, policy, MCP, inter-pack, and release scripts
- CI, security, docs-truth, compatibility-lock, template-drift, Docker, and PowerShell Gallery workflows

The release is not done until the module imports cleanly, all exported functions are present and callable, the CI/test envelope is green, release automation is coherent, documentation truth matches code, and no stale audit/probe artifacts contradict release state.

## Project Map to Use

### App type

This is a PowerShell-native toolkit, not a web/mobile/game app.

Primary module:

```powershell
module/LLMWorkflow/LLMWorkflow.psd1
module/LLMWorkflow/LLMWorkflow.psm1
```

Declared version line:

```text
VERSION
module/LLMWorkflow/LLMWorkflow.psd1
compatibility.lock.json
README.md
docs/releases/RELEASE_STATE.md
```

### Main runtime requirements

- Windows PowerShell 5.1 support is release-critical.
- PowerShell 7+ support is required where `pwsh` lanes exist.
- Python 3.11 is used in CI for ChromaDB and integration lanes.
- Pester 5.5+ is the test baseline.
- PSScriptAnalyzer is the lint baseline.
- Optional release publishing depends on repository secrets:
  - `PSGALLERY_API_KEY`
  - `CODESIGN_PFX_BASE64`
  - `CODESIGN_PFX_PASSWORD`

### Main folders

```text
.github/workflows/          GitHub Actions CI, CodeQL, release, supply-chain, publishing
module/LLMWorkflow/         PowerShell module root
module/LLMWorkflow/core/    core primitives: config, policy, state, locks, journaling
module/LLMWorkflow/workflow/ operator workflow and durable execution
module/LLMWorkflow/pack/    pack manifests, source registry, transactions
module/LLMWorkflow/ingestion/ extraction and ingestion adapters/parsers
module/LLMWorkflow/retrieval/ query routing, cache, caveats, incident bundles
module/LLMWorkflow/governance/ legacy governance shims
module/LLMWorkflow/contexts/ modular bounded contexts
module/LLMWorkflow/mcp/     MCP registry, gateway, lifecycle, toolkit surfaces
module/LLMWorkflow/telemetry/ tracing and dashboard helpers
module/LLMWorkflow/templates/ install/bootstrap templates
tools/ci/                   CI validators and Pester runner
tools/release/              version bumping and release tag tooling
tools/workflow/             global bootstrap/check/doctor/install wrappers
tools/codemunch/            CodeMunch project tooling templates
tools/contextlattice/       ContextLattice project tooling templates
tools/memorybridge/         MemPalace sync tooling templates
scripts/security/           SBOM, secret scan, vulnerability scan, security baseline
scripts/                    release certification
tests/                      Pester suites and integration tests
docs/                       architecture, operations, reference, release, implementation docs
packs/                      pack manifests and MCP manifests
policy/opa/                 Rego policy bundles
docker/                     Linux/Windows entrypoints and bootstrap wrappers
```

### Primary commands to verify

Run from repository root.

```powershell
# Dependency/setup validation
Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck -MinimumVersion 5.5.0
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
Install-Module InvokeBuild -Scope CurrentUser -Force

# Module import and exported surface smoke
Import-Module .\module\LLMWorkflow\LLMWorkflow.psd1 -Force
Get-Command -Module LLMWorkflow

# CI validators
.\tools\ci\check-template-drift.ps1
.\tools\ci\validate-compatibility-lock.ps1
.\tools\ci\validate-docs-truth.ps1

# Tests
.\tools\ci\invoke-pester-safe.ps1 -Path .\tests -CI

# Security/release
. .\scripts\security\Invoke-SecretScan.ps1; Invoke-SecretScan -ProjectRoot .
. .\scripts\security\Invoke-VulnerabilityScan.ps1; Invoke-VulnerabilityScan -ProjectRoot .
. .\scripts\security\Invoke-SBOMBuild.ps1; Invoke-SBOMBuild -ProjectRoot .
. .\scripts\security\Invoke-SecurityBaseline.ps1; Invoke-SecurityBaseline -ProjectRoot . -FailOnCritical
.\scripts\Invoke-ReleaseCertification.ps1 -ProjectRoot . -Strict

# Build wrapper, once restored
.\tools\build\Invoke-LLMBuild.ps1 -Lint
.\tools\build\Invoke-LLMBuild.ps1 -Test -CI
.\tools\build\Invoke-LLMBuild.ps1 -WhatIf
```

## Highest-Severity Findings to Fix First

### P0 — CI invokes a missing build script

`.github/workflows/ci.yml` calls:

```powershell
.\tools\build\Invoke-LLMBuild.ps1 -Lint
```

`tools/build/Invoke-LLMBuild.ps1` is missing on `ci-fixes-attempt`. Fix this before trusting any CI signal.

Required behavior:

- `-Lint`: run PSScriptAnalyzer over `module/LLMWorkflow`, use custom rules if `tools/build/PSScriptAnalyzer/*.psm1` exists, fail on errors, surface warnings.
- `-Test`: delegate to `tools/ci/invoke-pester-safe.ps1`.
- `-Docs`: run docs-truth validation; do not pretend to generate docs unless an actual generator exists.
- `-WhatIf`: run release guard checks without mutating state.
- no switches: run the default release-safe build sequence.

### P0 — release docs contain mojibake on the branch

Several branch docs contain broken UTF-8/Windows-1252 mojibake such as:

```text
Â·
â€”
âœ…
ðŸ”´
ðŸŸ 
```

This affects release-facing docs and makes documentation-truth claims untrustworthy until fixed.

Required behavior:

- restore proper UTF-8 text
- avoid re-saving files through the wrong encoding path
- add/keep a docs-truth or encoding guard that fails on common mojibake sequences in release-facing docs

### P0 — stale checked-in scratch artifacts contradict release state

Remove from release scope:

```text
_content_probe.txt
f
```

`_content_probe.txt` is a probe artifact. `f` is stale JSON-like audit state that still lists blockers as pending and contradicts README/release-state docs.

### P0 — `tasks/task_progress.json` is stale

The branch README and progress docs claim blockers are resolved, but `tasks/task_progress.json` still lists multiple blockers as pending. Either make this file the source of truth and update it honestly, or remove it from release artifacts if it is obsolete. Do not leave contradictory release metadata.

### P1 — branch is diverged from main

The branch is ahead and behind `main`. Before certification, reconcile the main-line change into `ci-fixes-attempt` and re-run the whole gate set.

## Required End-to-End Surfaces

For each public function listed in `LLMWorkflow.psd1`, verify:

```text
manifest export -> loader source path -> function definition -> command discovery -> happy-path call -> error-path call -> tests or smoke evidence
```

Minimum public command surfaces:

```text
llmup
llmdown
llmcheck
llmver
llmupdate
llmplugins
llmpalaces
llmsync
llmdashboard
llmheal
```

Minimum functional surfaces:

```text
Install-LLMWorkflow
Uninstall-LLMWorkflow
Update-LLMWorkflow
Get-LLMWorkflowVersion
Test-LLMWorkflowSetup
Invoke-LLMWorkflowUp
Invoke-LLMWorkflowHeal
Test-LLMWorkflowIssue
Repair-LLMWorkflowIssue
Show-LLMWorkflowDashboard
Show-PackHealthDashboard
Show-RetrievalActivityDashboard
Show-CrossPackGraph
Show-MCPGatewayStatus
Show-FederationStatus
Export-DashboardHTML
Register-LLMWorkflowPlugin
Get-LLMWorkflowPlugins
Unregister-LLMWorkflowPlugin
Invoke-LLMWorkflowPlugins
Get-LLMWorkflowPalaces
Sync-LLMWorkflowAllPalaces
New-LLMWorkflowGamePreset
Get-LLMWorkflowGameTemplates
Export-LLMWorkflowAssetManifest
Invoke-LLMWorkflowGameUp
Invoke-StructuredExtraction
Invoke-BatchExtraction
Export-ExtractionReport
New-IngestionJob
Start-IngestionJob
Get-IngestionJob
Stop-IngestionJob
Remove-IngestionJob
Register-IngestionSource
Test-IngestionSource
Get-IngestionMetrics
```

## Search for Incomplete Work

Use PowerShell-native search and inspect both source and docs.

Search terms:

```text
TODO
FIXME
WIP
stub
placeholder
mock
fake
dummy
sample
temp
coming soon
not implemented
throw "NotImplemented
throw 'NotImplemented
throw new Error
Write-Host
Write-Warning
-ErrorAction SilentlyContinue
catch {
Invoke-Expression
exit
$global:
hardcoded
example.test
your-api-key
replace-with-your
_content_probe
```

PowerShell-specific failure patterns:

```text
empty catch blocks
catch blocks that only continue
Write-Host in reusable module functions
Export-ModuleMember inside dot-sourced scripts that are not modules
functions declared in manifest but not loaded by LLMWorkflow.psm1
dot-source order dependencies
PSScriptRoot corruption after shim loading
PowerShell 7-only syntax in 5.1 paths
ConvertFrom-Json -AsHashtable in 5.1 paths
Path separator bugs between Windows and Linux/macOS
Remove-Item -ErrorAction SilentlyContinue in destructive paths
Invoke-RestMethod without timeout/error handling
Invoke-WebRequest without checksum validation where downloading release artifacts
```

## Release Priority Order for This Repo

### Phase 0 — import, CI, and release gate blockers

Fix:

- missing `tools/build/Invoke-LLMBuild.ps1`
- branch/main divergence
- docs mojibake
- stale scratch artifacts
- stale task progress truth
- module import failures
- manifest exports that do not exist after import
- CI YAML references to missing scripts
- release workflow references to missing scripts or wrong version paths

### Phase 1 — loader and exported command surface

Fix:

- `LLMWorkflow.psm1` loader order
- context `LoadOrder.psd1` usage or deliberate non-usage
- `LLMWorkflow.psd1` FunctionsToExport parity
- aliases pointing to missing functions
- legacy shims with broken `$PSScriptRoot` assumptions
- direct dot-sourcing compatibility for tests

### Phase 2 — operator workflows

Trace:

```text
llmup -> project bootstrap -> tools copied -> .env handling -> ContextLattice skip/verify -> MemPalace bridge skip/dry-run -> result object -> warnings/errors
llmcheck -> setup checks -> env/config detection -> optional connectivity -> structured result
llmheal -> diagnostics -> repair plan -> repair action -> repair history -> export/clear flows
llmdashboard -> telemetry/readiness checks -> dashboard display/export -> degraded-state messages
```

### Phase 3 — game asset and mixed artifact flows

Trace:

```text
New-LLMWorkflowGamePreset -> folder/template creation -> game-preset.json -> asset manifest
Export-LLMWorkflowAssetManifest -> scan folders -> classify assets -> merge existing metadata -> persist manifest
Invoke-StructuredExtraction -> parser selection -> output object -> report/export path
```

### Phase 4 — governance/golden task flows

Trace:

```text
Get-PredefinedGoldenTasks -> task definitions
New-GoldenTask -> schema
Invoke-GoldenTask -> provider/query execution -> result validation -> optional persistence
Invoke-GoldenTaskSuite -> suite iteration -> metrics/export/report
```

Do not leave simulated LLM calls visible as production behavior unless explicitly marked and gated as an offline/test adapter.

### Phase 5 — persistence, storage, and data truth

Verify:

- `.llm-workflow/` config paths
- game-preset persistence
- asset manifest persistence
- plugin registry persistence
- palace registry/sync state
- repair history
- retrieval cache
- golden task results
- ingestion job state
- certification/security reports

### Phase 6 — security and release evidence

Verify:

- secret scan does not suppress real findings
- vulnerability scan gates criticals
- SBOM output is generated and attached in release flow
- code-signing requirement is documented and enforced consistently
- security reports are generated but not committed unless intentionally curated
- `.gitignore` excludes generated reports and probe artifacts

### Phase 7 — docs truth and release packaging

Verify:

- README, VERSION, manifest version, compatibility lock, changelog, and release state agree
- docs-truth validator includes the metrics it claims
- release notes use the real version
- release archive contains only the module payload expected by PowerShell Gallery/GitHub Release
- release workflow fails clearly when required secrets are absent

## Done Criteria

The branch is a release candidate only when all of these are true:

- `Import-Module .\module\LLMWorkflow\LLMWorkflow.psd1 -Force` succeeds in Windows PowerShell 5.1 and PowerShell 7.
- Every `FunctionsToExport` entry exists after import.
- Every alias resolves to a real function.
- `tools/build/Invoke-LLMBuild.ps1` exists and matches CI usage.
- `tools/ci/check-template-drift.ps1` passes.
- `tools/ci/validate-compatibility-lock.ps1` passes.
- `tools/ci/validate-docs-truth.ps1` passes.
- `tools/ci/invoke-pester-safe.ps1 -Path .\tests -CI` passes.
- `Invoke-SecurityBaseline -FailOnCritical` passes.
- `Invoke-ReleaseCertification.ps1 -Strict` passes.
- No release-facing docs contain mojibake.
- No scratch/probe files are checked in.
- No stale audit state contradicts release-state docs.
- Release workflow package generation is verified.
- Any remaining hardening backlog is accurately documented as post-release or pre-v1.0, not falsely marked complete.

## Final Report Required

Report exactly:

- project map
- entry points and commands
- release surfaces
- incomplete work found
- blockers fixed
- functions/commands wired
- stale artifacts removed
- docs truth corrections
- tests added or updated
- commands run
- commands passed
- commands failed
- commands blocked by environment
- remaining unverified items
- release risks
- final go/no-go
