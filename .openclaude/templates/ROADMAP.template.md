# Target Release: release/vX.Y.Z

> **Execution Directive for OpenClaude Agents:**
> 1. Always reference `PROJECT_CONTEXT.md` before initiating any task.
> 2. Create isolated task branches off `release/vX.Y.Z` using the branch naming convention provided per item.
> 3. Do NOT attempt to resolve P1 or P2 tasks while P0 blockers remain open.
> 4. Halt execution and trigger Human-in-the-Loop (HITL) review if destructive changes or architecture ambiguities arise.

---

## 🚨 P0 Priority — Critical Blockers & Vulnerabilities
*Branch Prefix: `fix/p0-<task-name>`*

- [ ] **[TASK-P0-01]** `<Short Vulnerability or Critical Bug Title>`
  * **Category:** `AppSec` | `Database` | `Architecture`
  * **Target Location:** `file_path:line_number` or component name
  * **Branch Name:** `fix/p0-<task-name>`
  * **Agent Assigned:** AppSec / DB Lead
  * **Scope & Remediation:** Brief summary of the issue (e.g., CWE ID / SQLi / Memory Leak) and expected fix.

---

## ⚡ P1 Priority — Core Features & Architecture Improvements
*Branch Prefix: `feat/p1-<feature-name>`*

- [ ] **[TASK-P1-01]** `<Short Feature or Architectural Change Title>`
  * **Category:** `Feature` | `Refactoring` | `UX/UI`
  * **Target Location:** `file_path` or module name
  * **Branch Name:** `feat/p1-<feature-name>`
  * **Agent Assigned:** Context Architect / UX/UI Lead
  * **Scope & Remediation:** Description of requirements, Web Vitals targets, or new service integration.

---

## 🛠️ P2 Priority — Code Optimizations & Tech Debt
*Branch Prefix: `refactor/p2-<task-name>`*

- [ ] **[TASK-P2-01]** `<Short Optimization Title>`
  * **Category:** `Optimization` | `a11y` | `Documentation`
  * **Target Location:** `file_path:line_number`
  * **Branch Name:** `refactor/p2-<task-name>`
  * **Agent Assigned:** DB Lead / UX/UI Lead
  * **Scope & Remediation:** Query refactoring, index creation, ARIA tags, or minor styling cleanup.

---

## 📊 Status Tracking Checklist

| Task ID | Severity | Assigned Agent | Branch | Status | HITL Approval |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TASK-P0-01** | `P0 CRITICAL` | AppSec | `fix/p0-...` | `[ Pending / In-Progress / Review / Merged ]` | `[ Required ]` |
| **TASK-P1-01** | `P1 HIGH` | Architect | `feat/p1-...` | `[ Pending / In-Progress / Review / Merged ]` | `[ Approved ]` |
| **TASK-P2-01** | `P2 MEDIUM` | UX/UI Lead | `refactor/p2-...` | `[ Pending / In-Progress / Review / Merged ]` | `[ Pending ]` |
