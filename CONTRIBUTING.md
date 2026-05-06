# Contributing to Repo Cortex

Thank you for your interest in contributing to Repo Cortex. This document covers the conventions, architecture, and workflow you need to know.

## Quick Start

```powershell
# Import the module
Import-Module .\module\LLMWorkflow\LLMWorkflow.psd1 -Force

# Run the full test suite
.\tools\ci\invoke-pester-safe.ps1 -Path .\tests -CI

# Run linting
.\tools\build\Invoke-LLMBuild.ps1 -Lint

# Run docs-truth validation
.\tools\build\Invoke-LLMBuild.ps1 -Docs

# Run a targeted build with boundary and size checks
.\tools\build\Invoke-LLMBuild.ps1 -Test -Lint
```

## Architecture

Repo Cortex is a single PowerShell module (`LLMWorkflow`) organized as a **modular monolith** using bounded contexts:

```
module/LLMWorkflow/
├── LLMWorkflow.psm1      # Root module (dot-sources everything)
├── LLMWorkflow.psd1      # Module manifest (exports)
├── core/                  # Primitives: config, logging, state, policy
├── contexts/              # Bounded contexts (the main architecture)
│   ├── _shared/           # Cross-cutting utilities
│   ├── Workflow/          # Core workflow orchestration
│   ├── Retrieval/         # RAG, vector search, answer integrity
│   ├── Ingestion/         # Extraction, parsers, document intake
│   ├── Governance/        # Policy, golden tasks, review gates
│   ├── MCP/               # Tool surface and gateway
│   ├── Telemetry/         # Dashboards, OTel bridge
│   ├── GameAssets/         # Game engine scaffolding
│   ├── Healing/           # Self-healing diagnostics
│   ├── Federation/        # Inter-pack transport
│   └── Platform/          # Cross-cutting platform concerns
├── retrieval/             # Retrieval subsystem (legacy layout)
├── governance/            # Governance subsystem (legacy layout)
├── mcp/                   # MCP subsystem (legacy layout)
├── ingestion/             # Ingestion + parsers (legacy layout)
└── ...
```

### Key Rules

1. **Bounded contexts must not cross-import** — files in `contexts/Governance/` must not dot-source files from `contexts/MCP/`. Use `_shared/` for cross-cutting concerns.
2. **300-line file limit** — enforced by `Invoke-LLMBuild.ps1`. If a file exceeds this, decompose it.
3. **Dependency graph** — the build system knows which contexts depend on which. See `$script:ContextGraph` in `tools/build/Invoke-LLMBuild.ps1`.

## Coding Standards

### PowerShell Style

- **`Set-StrictMode -Version Latest`** in reusable modules
- **`[CmdletBinding()]`** on all exported and semi-public functions
- **`[OutputType()]`** on functions where the return type is meaningful
- **`.SYNOPSIS`** help comment on public functions
- Use **approved PowerShell verbs** (`Get-`, `Set-`, `New-`, `Invoke-`, etc.)
- Avoid `Write-Host` in reusable modules — use `Write-Output`, `Write-Verbose`, or `Write-Information`
- Avoid `-ErrorAction SilentlyContinue` unless justified with a comment

### Error Handling

- Use the patterns in `workflow/FailureTaxonomy.ps1` for error categorization
- Never use empty `catch {}` blocks
- Avoid `Invoke-Expression` in production paths
- Make degraded-mode behavior visible via structured diagnostics

### PowerShell 5.1 Compatibility

The module targets PowerShell 5.1+. Common pitfalls:
- No `ConvertFrom-Json -AsHashtable` (use `ConvertTo-Hashtable` helper)
- No `[System.IO.File]::Move()` 3-arg overload (copy + delete pattern)
- No ternary operator `$x ? $a : $b` (use `if`/`else`)
- Guard PS7-only features with `Test-PSVersionRequirement`

## Adding a New Function

1. Create the `.ps1` file in the appropriate context directory under `module/LLMWorkflow/contexts/`
2. If the function should be public, add it to `FunctionsToExport` in `LLMWorkflow.psd1`
3. If adding an alias, add it to `AliasesToExport` in `LLMWorkflow.psd1`
4. Update the module count in `docs/releases/RELEASE_STATE.md`, `README.md`, and `docs/implementation/PROGRESS.md`
5. Add tests in `tests/`
6. Run `.\tools\build\Invoke-LLMBuild.ps1 -Docs` to verify docs-truth

## Adding a Domain Pack

1. Create a manifest JSON in `packs/manifests/`
2. Create a source registry in `packs/registries/`
3. Optionally add an MCP toolkit descriptor in `packs/mcp-toolkits/`
4. Add golden task stubs via `New-LLMWorkflowPackScaffold`
5. Update the domain pack count in the three documentation files

## Testing

- All tests use **Pester v5** syntax
- Tests go in `tests/` with the naming convention `<Feature>.Tests.ps1`
- Run with `.\tools\ci\invoke-pester-safe.ps1`
- The build orchestrator can run only affected tests: `.\tools\build\Invoke-LLMBuild.ps1 -Test`

### Test Naming Convention

```powershell
Describe "Feature or Module Name" {
    Context "When <scenario>" {
        It "should <expected behavior>" {
            # Arrange, Act, Assert
        }
    }
}
```

## CI Pipeline

The CI pipeline runs automatically on pushes to `main` and pull requests:

1. **drift-guard** — Template drift, compatibility lock, docs-truth validation
2. **lint** — PSScriptAnalyzer
3. **windows-ci** — Full Pester suite (PowerShell 5.1 + PowerShell 7)
4. **linux-ci / macos-ci** — Cross-platform experimental
5. **e2e-integration** — ContextLattice integration tests
6. **Security baseline gate** — Secret scanning, SBOM, vulnerability scan

## Release Process

See `docs/releases/RELEASE_STATE.md` for current state and `docs/releases/V1_RELEASE_CRITERIA.md` for exit criteria.

```powershell
# Run release certification
.\scripts\Invoke-ReleaseCertification.ps1 -ProjectRoot . -Strict

# Run release preflight
.\tools\release\test-release-prereqs.ps1 -ProjectRoot .

# Bump version
.\tools\release\bump-module-version.ps1 -Version 1.0.0

# Tag and push
.\tools\release\create-release-tag.ps1 -Push
```

## Documentation Truth

Repo Cortex enforces documentation consistency. When you change module counts, exported functions, or other tracked metrics:

1. Update `README.md`
2. Update `docs/releases/RELEASE_STATE.md`
3. Update `docs/implementation/PROGRESS.md`
4. Run `.\tools\build\Invoke-LLMBuild.ps1 -Docs` to verify

The docs-truth validator will block CI if counts are misaligned.
