# Repo Cortex Operator Experience Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the seven post-v1 operator features as tested, module-exported Repo Cortex commands.

**Architecture:** Keep the first pass PowerShell-native and file-backed. Add a focused operations API layer under `module/LLMWorkflow/contexts/Workflow/api/`, export the commands from the manifest and root module, and document the command surface in README/release docs.

**Tech Stack:** PowerShell 5.1-compatible functions, Pester 5 tests, JSON file artifacts, existing module loader/export patterns.

---

### Task 1: Operator Experience Tests

**Files:**
- Create: `tests/OperatorExperience.Tests.ps1`

- [ ] **Step 1: Write failing tests**

Create Pester tests covering:
- `Get-LLMWorkflowNextAction` ranks failed certification above clean release state.
- `Export-LLMWorkflowEvidenceReport` writes normalized trace/evidence JSON and HTML.
- `New-LLMWorkflowPackScaffold` creates pack manifest, source registry, and golden task stub.
- `Invoke-LLMWorkflowCorpusRegression` summarizes corpus cases and writes a report.
- `Test-LLMWorkflowSecurityExceptions` flags expired exceptions.
- `Export-LLMWorkflowCockpit` writes a local HTML cockpit containing health, next action, and release evidence sections.
- `Update-LLMWorkflowProject -Plan` reports migration actions without mutating files.

- [ ] **Step 2: Run tests to verify red**

Run:

```powershell
.\tools\ci\invoke-pester-safe.ps1 -Path .\tests\OperatorExperience.Tests.ps1 -CI
```

Expected: fails because the new commands are not exported yet.

### Task 2: Operations API Implementation

**Files:**
- Create: `module/LLMWorkflow/contexts/Workflow/api/Get-LLMWorkflowNextAction.ps1`
- Create: `module/LLMWorkflow/contexts/Workflow/api/Export-LLMWorkflowEvidenceReport.ps1`
- Create: `module/LLMWorkflow/contexts/Workflow/api/New-LLMWorkflowPackScaffold.ps1`
- Create: `module/LLMWorkflow/contexts/Workflow/api/Invoke-LLMWorkflowCorpusRegression.ps1`
- Create: `module/LLMWorkflow/contexts/Workflow/api/Test-LLMWorkflowSecurityExceptions.ps1`
- Create: `module/LLMWorkflow/contexts/Workflow/api/Export-LLMWorkflowCockpit.ps1`
- Create: `module/LLMWorkflow/contexts/Workflow/api/Update-LLMWorkflowProject.ps1`

- [ ] **Step 1: Implement minimal green behavior**

Each command must be deterministic, PowerShell 5.1-compatible, and must return objects suitable for CI automation.

- [ ] **Step 2: Run operator tests**

Run:

```powershell
.\tools\ci\invoke-pester-safe.ps1 -Path .\tests\OperatorExperience.Tests.ps1 -CI
```

Expected: pass.

### Task 3: Export Surface and Aliases

**Files:**
- Modify: `module/LLMWorkflow/LLMWorkflow.psd1`
- Modify: `module/LLMWorkflow/LLMWorkflow.psm1`
- Modify: `tests/ModuleExportSurface.Tests.ps1`

- [ ] **Step 1: Export functions and aliases**

Add functions:
- `Get-LLMWorkflowNextAction`
- `Export-LLMWorkflowEvidenceReport`
- `New-LLMWorkflowPackScaffold`
- `Invoke-LLMWorkflowCorpusRegression`
- `Test-LLMWorkflowSecurityExceptions`
- `Export-LLMWorkflowCockpit`

Keep the existing `Update-LLMWorkflowProject` export if present; otherwise add it. Add aliases:
- `llmnext`
- `llmcockpit`
- `llmpacknew`
- `llmcorpus`
- `llmsecx`

- [ ] **Step 2: Run export tests**

Run:

```powershell
.\tools\ci\invoke-pester-safe.ps1 -Path .\tests\ModuleExportSurface.Tests.ps1 -CI
```

Expected: pass.

### Task 4: Documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/releases/RELEASE_CERTIFICATION_CHECKLIST.md`
- Modify: `docs/implementation/LLMWorkflow_Post_0.9.6_Strategic_Execution_Plan.md`

- [ ] **Step 1: Document commands**

Add a concise "Operator Experience" section describing the seven additions and their commands.

- [ ] **Step 2: Validate docs truth**

Run:

```powershell
.\tools\ci\validate-docs-truth.ps1
```

Expected: exit 0.

### Task 5: Final Verification

**Files:**
- No new edits unless verification finds a defect.

- [ ] **Step 1: Run targeted tests**

Run:

```powershell
.\tools\ci\invoke-pester-safe.ps1 -Path .\tests\OperatorExperience.Tests.ps1 -CI
.\tools\ci\invoke-pester-safe.ps1 -Path .\tests\ModuleExportSurface.Tests.ps1 -CI
```

- [ ] **Step 2: Run release certification tests**

Run:

```powershell
.\tools\ci\invoke-pester-safe.ps1 -Path .\tests\ReleaseCertification.Tests.ps1 -CI
```

- [ ] **Step 3: Inspect git diff**

Run:

```powershell
git status --short
git diff --stat
```

Report changed files and any verification gaps.
