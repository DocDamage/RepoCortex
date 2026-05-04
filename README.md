# CodeMunch + ContextLattice + MemPalace (All-in-One)

[![Version](https://img.shields.io/badge/version-0.9.6-blue.svg)](https://github.com/DocDamage/CodeMunch-ContextLattice-MemPalace---All-in-one/blob/work/VERSION)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Packs](https://img.shields.io/badge/domain%20packs-10-green.svg)](#domain-packs)
[![Parsers](https://img.shields.io/badge/extraction%20parsers-30-orange.svg)](#platform-scope)
[![Golden Tasks](https://img.shields.io/badge/golden%20tasks-60-purple.svg)](#testing)

> Canonical toolkit repo for the integrated CodeMunch · ContextLattice · MemPalace workflow.

---

## Project Status

**Current Version:** `0.9.6` · **Target:** `v1.0` · **Branch:** `work`

This repository is in active **post-0.9.6 hardening and release-state reconciliation**. All eight implementation phases are complete, and the codebase is undergoing final remediation toward v1.0 certification.

An [**AAA Production Release Audit**](AAA_RELEASE_AUDIT_REPORT.md) was completed on **2026-05-03**. Remediation status:

| Severity | Original | Resolved | Remaining |
|----------|----------|----------|-----------|
| 🔴 Blocker | 6 | 5 | 1 — systematic `-ErrorAction SilentlyContinue` reduction (critical paths cleared; repo-wide sweep in progress) |
| 🟠 High | 15 | 14 | 1 — ongoing observability hardening |

**Resolved blockers:** version fragmentation unified, mock data removed from dashboards, CDN vendoring eliminated, credential exposure vectors closed, missing documentation produced.  
**Resolved high issues:** module-loader guard added, Dockerfile/composer hardened, requirements manifest expanded, dashboard `exit()` removed, duplicate provider functions deduplicated, retrieval metrics now distinguish "no data" from "zero data", exception suppression elevated to warnings, empty catch blocks eliminated, cross-platform path separators fixed, SBOM/security reports generated, release certification alignment completed, plugin exports completed.

Progress is tracked in [`docs/implementation/PROGRESS.md`](docs/implementation/PROGRESS.md) and [`docs/implementation/REMAINING_WORK.md`](docs/implementation/REMAINING_WORK.md).

> **Note:** This branch (`work`) is the active development line. Do not treat it as a stable release target until `Invoke-ReleaseCertification.ps1` passes all categories.

---

## What Is This?

A unified PowerShell-native toolkit that wires together three subsystems:

- **CodeMunch** — Project indexing, MCP wrapper setup, and searchable code context
- **ContextLattice** — Project bootstrap, orchestrator connectivity, and verification
- **MemPalace** — Vector storage (ChromaDB) with incremental bridge sync to ContextLattice

### Why Use This Toolkit?

**For AI-Assisted Development**
- **One-command bootstrap:** `llmup` scaffolds the entire toolchain
- **Multi-provider LLM support:** OpenAI, Claude, Kimi, Gemini, GLM, and Ollama with auto-detection and alias env-var handling
- **Memory persistence:** MemPalace + ContextLattice bridge sync preserves project context across sessions
- **Provider resolver hardening:** Explicit override fallback, base-URL precedence, and key-validation edge cases are covered

**For Game Development**
- **Game-team preset:** `llmup -GameTeam` scaffolds engine-aware project structure
- **Asset management:** Manifests, license tracking, and game-team templates for Godot, RPG Maker MZ, Blender, and Unreal
- **Jam mode:** Fast startup path for rapid prototyping
- **Structured extraction:** Godot, RPG Maker, Blender, OpenAPI, shader, schema, YAML, JSON, SQL, and Docker parsers

**For Operations and CI**
- **Cross-platform CI:** Windows primary matrix (`powershell` / `pwsh`) with Linux/macOS experimental lanes
- **Safe test runner:** `tools/ci/invoke-pester-safe.ps1`
- **Docs-truth and drift guards:** Compatibility-lock validation, template-drift detection, docs validation
- **Security baselines:** SBOM, secret-scan, vulnerability-scan, and security-baseline reports generated under [`security-reports/`](security-reports/)

---

## Platform Scope

| Area | Count |
|------|------:|
| Domain packs | 10 |
| PowerShell module | 1 (`LLMWorkflow`) |
| Exported functions | 54 |
| Source scripts | 130+ |
| Extraction parsers | 30 |
| Golden tasks | 60 |
| Benchmark suites | 5 |
| MCP tool surface | 55 |

---

## Architecture

The platform is organized around a unified PowerShell workflow layer that coordinates indexing, verification, sync, extraction, retrieval, governance, and MCP tooling.

Core lanes:
- **Core infrastructure:** Run IDs, journaling, atomic writes, config, policy, execution modes, workspaces, visibility
- **Pack framework:** Manifests, source registries, lockfiles, transactions, compatibility
- **Extraction:** Domain-specific parsers and batch extraction support
- **Retrieval and integrity:** Routing, confidence policy, answer planning, caveats, caching, incident bundles
- **Governance:** Golden tasks, review gates, human annotations, replay, pack SLOs
- **Expansion:** MCP, inter-pack pipelines, snapshots, external ingestion, federated memory

For detailed architecture, see [`docs/architecture/ARCHITECTURE.md`](docs/architecture/ARCHITECTURE.md).

---

## Domain Packs

| Pack | Status | Focus |
|------|--------|-------|
| `godot-engine` | ✅ Promoted | Godot engine development, GDScript, scenes, signals |
| `blender-engine` | ✅ Promoted | Blender automation, operators, geometry nodes, export workflows |
| `rpgmaker-mz` | ✅ Promoted | RPG Maker plugin development, conflict diagnosis, notetags |
| `voice-audio-generation` | ✅ Promoted | Voice, TTS/STS, audio generation pipelines |
| `agent-simulation` | ✅ Promoted | Agent workflows and simulation patterns |
| `notebook-data-workflow` | ✅ Promoted | Notebook and data workflow extraction |
| `ui-frontend-framework` | ✅ Promoted | UI/component and design-system workflows |
| `api-reverse-tooling` | ✅ Promoted | API discovery, reverse engineering, documentation |
| `ml-educational-reference` | ✅ Promoted | ML educational and reference content |
| `engine-reference` | ✅ Promoted | Cross-engine patterns and migration guidance |

---

## Installation

### Recommended: module import

```powershell
Import-Module .\module\LLMWorkflow\LLMWorkflow.psd1 -Force
Install-LLMWorkflow -NoProfileUpdate
```

Then in any project:

```powershell
Invoke-LLMWorkflowUp
# alias
llmup
```

### Global script install

```powershell
.\tools\workflow\install-global-llm-workflow.ps1
```

### Uninstall

```powershell
Uninstall-LLMWorkflow
# alias
llmdown
```

---

## Common Commands

| Command | Purpose |
|---------|---------|
| `llmup` | Bootstrap project workflow |
| `llmcheck` | Validate setup |
| `llmver` | Show version |
| `llmupdate` | Update toolkit |
| `llmdashboard` | Interactive dashboard |
| `llmheal` | Self-healing diagnostics |

### Game Team Workflow

```powershell
llmup -GameTeam -GameTemplate "topdown-rpg" -GameEngine "Godot"
llmup -GameTeam -JamMode
```

Game-oriented structure includes:
- `docs/GDD.md`
- `docs/TASKS.md`
- `assets/ASSET_MANIFEST.json`
- `assets/art`, `spritesheets`, `tilemaps`, `sfx`, `music`, `plugins`
- `.llm-workflow/game-preset.json`

---

## Plugin Architecture

Third-party tools can register through `.llm-workflow/plugins.json`.

```powershell
Register-LLMWorkflowPlugin -ManifestPath "tools/my-plugin/manifest.json"
Get-LLMWorkflowPlugins
Unregister-LLMWorkflowPlugin -Name "my-plugin"
```

---

## Testing

The branch baseline is exercised through the full `tests/` envelope:

- Full `tests/` execution via `tools/ci/invoke-pester-safe.ps1`
- Windows CI matrix (`powershell` + `pwsh`)
- Linux/macOS experimental Pester lanes
- Install/bootstrap smoke
- Docs-truth validation
- Compatibility-lock validation
- Template drift validation
- ContextLattice integration lane

### Local invocation

```powershell
Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck
.\tools\ci\invoke-pester-safe.ps1 -Path .\tests -CI
```

### Hardening now covered
- Provider resolver priority order and `LLM_PROVIDER` override fallback
- Alias environment variable handling (`MOONSHOT_API_KEY`, `GOOGLE_API_KEY`, `ZHIPU_API_KEY`)
- Base-URL precedence and fallback (`OLLAMA_HOST` / `OLLAMA_BASE_URL`)
- Curated-plugin compatibility fixtures (active, deprecated, quarantined, retired, mixed)
- Primitive test suites (AtomicWrite, CommandContract, FileLock, Journal, StateFile, Workspace)
- Golden Task Evaluations (60 tasks)

CI workflows:
- `.github/workflows/ci.yml`
- `.github/workflows/gitleaks.yml`
- `.github/workflows/codeql.yml`
- `.github/workflows/release.yml`
- `.github/workflows/publish-gallery.yml`
- `.github/workflows/supply-chain.yml`
- `.github/workflows/docker-build.yml`

---

## Security & Compliance

Recent audits have produced the following artifacts:

- [`security-reports/sbom-2026-05-03T04-54-46Z.json`](security-reports/sbom-2026-05-03T04-54-46Z.json)
- [`security-reports/secret-scan-2026-05-03T04-54-46Z.json`](security-reports/secret-scan-2026-05-03T04-54-46Z.json)
- [`security-reports/security-baseline-2026-05-03T04-54-46Z.json`](security-reports/security-baseline-2026-05-03T04-54-46Z.json)
- [`security-reports/vulnerability-scan-2026-05-03T04-54-46Z.json`](security-reports/vulnerability-scan-2026-05-03T04-54-46Z.json)

Run certification locally:

```powershell
.\scripts\Invoke-ReleaseCertification.ps1 -ProjectRoot .
```

---

## Release

```powershell
.\tools\release\bump-module-version.ps1 -Version 0.10.0
git add .
git commit -m "Release 0.10.0"
.\tools\release\create-release-tag.ps1 -Push
```

PowerShell Gallery publishing is automated on GitHub Release publish when `PSGALLERY_API_KEY` is configured in repository secrets.

---

## Documentation Index

| Document | Purpose |
|----------|---------|
| [`docs/implementation/PROGRESS.md`](docs/implementation/PROGRESS.md) | Canonical implementation progress tracker |
| [`docs/implementation/LLMWorkflow_Post_0.9.6_Strategic_Execution_Plan.md`](docs/implementation/LLMWorkflow_Post_0.9.6_Strategic_Execution_Plan.md) | Post-0.9.6 execution plan |
| [`docs/implementation/TECHNICAL_DEBT_AUDIT.md`](docs/implementation/TECHNICAL_DEBT_AUDIT.md) | Technical debt findings |
| [`docs/implementation/REMAINING_WORK.md`](docs/implementation/REMAINING_WORK.md) | Exit criteria and backlog before v1.0 |
| [`docs/implementation/CURRENT_TEST_BASELINE_AND_RESOLVER_HARDENING.md`](docs/implementation/CURRENT_TEST_BASELINE_AND_RESOLVER_HARDENING.md) | Test baseline and resolver hardening details |
| [`docs/architecture/ARCHITECTURE.md`](docs/architecture/ARCHITECTURE.md) | Detailed architecture diagrams and component explanations |
| [`docs/architecture/PLATFORM_OVERVIEW.md`](docs/architecture/PLATFORM_OVERVIEW.md) | High-level platform overview |
| [`docs/architecture/SECURITY_BASELINE.md`](docs/architecture/SECURITY_BASELINE.md) | Security baseline architecture |
| [`docs/releases/V1_RELEASE_CRITERIA.md`](docs/releases/V1_RELEASE_CRITERIA.md) | v1.0 release criteria |
| [`docs/releases/RELEASE_CERTIFICATION_CHECKLIST.md`](docs/releases/RELEASE_CERTIFICATION_CHECKLIST.md) | Release certification checklist |
| [`AAA_RELEASE_AUDIT_REPORT.md`](AAA_RELEASE_AUDIT_REPORT.md) | AAA production release audit (2026-05-03) |
| [`CHANGELOG.md`](CHANGELOG.md) · [`docs/releases/CHANGELOG.md`](docs/releases/CHANGELOG.md) | Change history |

---

## Notes

- Keep secrets in local `.env` files and **never commit them**.
- Use `CONTEXTLATTICE_ORCHESTRATOR_API_KEY` in `.env` or `.contextlattice/orchestrator.env` for ContextLattice auth.
- For deeper implementation state, see [`docs/implementation/PROGRESS.md`](docs/implementation/PROGRESS.md).
