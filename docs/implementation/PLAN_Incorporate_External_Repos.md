# Plan: Incorporate Selected External Repositories

## Goal
Add `nightlark/pymsi` as a release/CI utility, manually evaluate `van3ll0pe/spritesheet_animation` for the Godot pack, and capture competitive intelligence from `GitNexus` and `AssistantMD` without importing their code.

## Approach
A single, minimal-incursion approach:
1. **Adopt** `pymsi` via Python dependency + PowerShell wrapper.
2. **Evaluate** the spritesheet project via a short spike and document the go/no-go decision.
3. **Research** the two AI-context engines in a standalone reference memo.

---

## Phase 1 — Add nightlark/pymsi (Release/CI Utility)

### 1.1 Declare the Python dependency
- **File:** `requirements.scan.txt`
- **Action:** Append `python-msi>=0.0.0b3` on a new line (keep `chromadb` on its own line).
- **Rationale:** The repo already uses `requirements.scan.txt` as the canonical Python dependency manifest. This is a pure-Python package, so no native build tooling is required.

### 1.2 Create a PowerShell wrapper
- **File:** `tools/release/Invoke-MsiInspection.ps1`
- **Action:** Write a thin wrapper that shells out to the `pymsi` CLI with common verbs:
  - `Test-MsiFile` → `pymsi test <path>`
  - `Get-MsiTables` → `pymsi tables <path>`
  - `Export-MsiContents` → `pymsi extract <path> <outdir>`
  - `Get-MsiDump` → `pymsi dump <path>`
- The wrapper should validate that `pymsi` is on the PATH or in the active Python environment, and emit a graceful warning with install instructions if missing.
- **Rationale:** The project is PowerShell-first; every external tool is surfaced through PowerShell functions/commands so CI and release scripts can consume it uniformly.

### 1.3 Document the utility
- **File:** `tools/release/README.md`
- **Action:** Add a new section "Windows Installer (MSI) Inspection" that shows:
  - Why it exists (release artifacts may include MSI payloads; we need a scriptable way to inspect/extract them).
  - One-liner install: `pip install python-msi`
  - Example: `Export-MsiContents -Path .\artifact.msi -OutputFolder .\msi_extracted`

### 1.4 Optional CI smoke test
- **File:** `tests/CoreModule.Tests.ps1` (or a new lightweight test file)
- **Action:** Add a Pester test that asserts `pymsi` is importable when Python is present and that `Invoke-MsiInspection` functions return the expected parameter metadata. This keeps the new utility under the existing `invoke-pester-safe.ps1` baseline.

---

## Phase 2 — Investigate van3ll0pe/spritesheet_animation

### 2.1 Spike (manual, outside repo)
- Clone/fetch `https://codeberg.org/van3ll0pe/spritesheet_animation` into a temporary directory.
- Evaluate in ≤30 minutes:
  - Language/runtime (Rust? GDScript? Python?)
  - Godot compatibility (Godot 3 vs 4, engine version, add-on vs standalone)
  - Scope (sprite atlas packing, animation playback, export formats)
  - License
  - Maintenance status (last commit date, open issues)

### 2.2 Document findings
- **File:** `docs/reference/Godot_Pack_Appendage_Additional_Candidate_Repositories_v2.md`
- **Action:** Add a new subsection under the appropriate priority tier (likely "Useful optional adds" or a new spritesheet-specific section).
- Include: repo URL, evaluated ref, license, one-paragraph fit assessment, and a **recommendation** (e.g., "Add to source registry" or "Defer — too narrow/unsupported").

### 2.3 Conditional registration
- **If recommended for adoption:**
  - **File:** `packs/registries/godot-engine.sources.json`
  - **Action:** Append a new entry with `sourceId`, `repoUrl`, `selectedRef`, `trustTier` (likely "Medium"), `authorityRole` ("asset-tooling"), `collections` (e.g., `["godot_visual_systems"]`), and `extractionTargets` matching the tool’s outputs.
- **If deferred:** simply note the deferral reason in the markdown appendage and stop.

---

## Phase 3 — Competitive Research (GitNexus + AssistantMD)

### 3.1 Create the research memo
- **File:** `docs/reference/COMPETITIVE_RESEARCH_AI_CONTEXT_ENGINES.md`
- **Action:** Produce a concise competitive-intelligence document (no code imports, no submodules) structured as:
  1. **Executive Summary** — both projects are markdown-native, AI-context engines that overlap with CodeMunch indexing and ContextLattice memory persistence.
  2. **GitNexus** — key ideas to study:
     - Graph-RAG over a local knowledge graph (LadybugDB).
     - MCP server exposing Cypher/code-navigation tools.
     - Auto-generated `AGENTS.md` / `CLAUDE.md` context files.
     - PreToolUse hooks that enrich searches with graph context.
  3. **AssistantMD** — key ideas to study:
     - Markdown-first chat transcripts and context templates.
     - Scheduled cron-like workflows inside vaults.
     - Conservative automation stance and prompt-injection awareness.
     - Multi-provider LLM routing in a Dockerized, self-hosted UI.
  4. **Implications for our stack** — bullet list of actionable takeaways for CodeMunch indexing, ContextLattice retrieval, and MemPalace bridge sync (e.g., "evaluate pre-computed context templates", "consider graph-backed retrieval substrate enhancements").

### 3.2 Reference, do not vendor
- Explicitly **do not** add GitNexus or AssistantMD as submodules, vendor copies, or runtime dependencies.
- The memo serves as the single source of truth for future architecture decisions.

---

## Rollback / Safety
- `pymsi` is a soft dependency; if it breaks, the wrapper scripts emit a warning and do not block release workflows.
- The spritesheet investigation is read-only and touches no production code unless Phase 2.3 is explicitly approved afterward.
- The competitive research memo is documentation-only.

## Estimated effort
- Phase 1: 1 hour (wrapper + docs + small test)
- Phase 2: 30 minutes (spike) + 15 minutes (documentation)
- Phase 3: 45 minutes (reading + memo writing)
