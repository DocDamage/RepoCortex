# AAA Production Release Remediation Plan

> [!IMPORTANT]
> **PLAN COMPLETED (2026-05-04)**
> All remediation phases documented below have been successfully executed, verified, and certified. The repository is now in a **v1.0 Release Candidate** state.

**Project:** CodeMunch-ContextLattice-MemPalace---All-in-one  
**Plan Date:** 2026-05-04  
**Source Audit:** `AAA_PRODUCTION_RELEASE_AUDIT_2026-05-04_LOCAL.md`  
**Current Branch:** `ci-fixes-attempt`

## Goal

Reduce release risk in the safest order: fix low-blast-radius correctness defects first, then align public command/provider contracts, then repair runtime wiring and release gates, and only then reconcile release claims and larger feature-state gaps.

## Execution Order

### Phase 1. Contained Runtime Correctness

1. **MemPalace bridge retry bug**
   - Fix missing `errno` import in `tools/memorybridge/sync_mempalace_to_contextlattice.py`.
   - Add a focused retry-path test that proves retryable `OSError` values do not crash classification and that retry logic retries before succeeding.
   - Validation:
     - `Invoke-Pester tests/MemoryBridge.Tests.ps1`

### Phase 2. Public Contract Alignment

2. **Module export surface**
   - Export `Test-LLMWorkflowPalace` and `Sync-LLMWorkflowPalace` from `module/LLMWorkflow/LLMWorkflow.psm1`.
   - Extend the module export test so documented palace commands are asserted.
   - Validation:
     - `Invoke-Pester tests/LLMWorkflow.Tests.ps1`

3. **Provider support consistency**
   - Align `tools/workflow/bootstrap-llm-workflow.ps1` and `tools/workflow/doctor-llm-workflow.ps1` with the provider set already supported by the module and docs.
   - Add or extend tests for `claude` and `ollama` acceptance where public entry points are validated.
   - Validation:
     - Narrow provider-related Pester coverage for bootstrap/doctor/module resolution

### Phase 3. Default Runtime Wiring

4. **Compose/orchestrator default wiring**
   - Decide one supported default:
     - add a real `contextlattice` service to `docker-compose.yml`, or
     - make the stack explicitly external-orchestrator-only and remove the misleading default host.
   - Update CI so the chosen default is exercised instead of silently skipped.
   - Validation:
     - `docker compose config`
     - focused compose/CI smoke for the chosen default

### Phase 4. Release Gate Hardening

5. **Release certification behavior checks**
   - Convert `scripts/Invoke-ReleaseCertification.ps1` away from file-presence-only checks for release-critical surfaces.
   - Add failures for broken module exports, broken compose defaults, missing current evidence artifacts, and mock-only retrieval.
   - Validation:
     - `Invoke-Pester tests/ReleaseCertification.Tests.ps1`
     - run `scripts/Invoke-ReleaseCertification.ps1` against the local repo

### Phase 5. Core Capability Truth

6. **Retrieval backend truth**
   - Either implement real Qdrant/LanceDB support and prove it in CI, or explicitly downgrade retrieval release claims and certification expectations until real adapters exist.
   - Validation:
     - retrieval tests against real services, not mock-only assertions

7. **Real integration lane**
   - Add one release-gating integration lane against a real ContextLattice deployment and real retrieval dependency.
   - Validation:
     - CI lane passes without `mock_contextlattice_server.py`

### Phase 6. Release Truth Reconciliation

8. **Top-level release and security evidence truth**
   - Update `README.md`, release-state docs, and generated evidence references only after the code and validation surfaces reflect reality.
   - Remove stale branch claims and stale/missing artifact references.
   - Validation:
     - documentation cross-check against current branch, generated artifacts, and current CI outputs

9. **Placeholder-backed released surfaces**
   - For compatibility, inter-pack, AI generation, and model deployment, either:
     - finish the production-critical paths and validate them, or
     - downgrade release-state claims to experimental/documented-head.
   - Validation:
     - release-state docs match the implementation and corresponding tests

## Why This Order Is Safest

- Phase 1 fixes a real runtime defect with a very small edit surface and a direct test.
- Phase 2 aligns public contracts before changing infrastructure or documentation, reducing downstream confusion.
- Phase 3 repairs the default runtime path before hardening certification around it.
- Phase 4 makes release gates trustworthy before using them to judge larger changes.
- Phase 5 handles the largest, highest-blast-radius capability gaps once the surrounding contracts and gates are stable.
- Phase 6 updates release claims last, so docs become a reflection of reality rather than a substitute for it.

## Immediate Next Step

Start with Phase 1: fix the bridge retry blocker and prove it with a dedicated narrow test before moving to the next blocker.