# Code Quality & Maintainability Audit Report: [Project Name / Module]

* **Date:** YYYY-MM-DD
* **Auditor Agent:** Lead Code Quality & Maintainability Engineer
* **Target Commit / Branch:** `[commit-hash-or-branch]`
* **Focus Areas:** Complexity, Duplication, Coding Standards, Testability, Tech Debt

---

## Executive Quality Summary

| Severity Priority | Maintainability Critical | Tech Debt | Style / Info | Total Issues |
| :--- | :---: | :---: | :---: | :---: |
| **P0 (Critical)** | 0 | 0 | 0 | 0 |
| **P1 (High)**     | 0 | 0 | 0 | 0 |
| **P2 (Medium)**   | 0 | 0 | 0 | 0 |

---

## Detailed Maintainability Findings

### [QA-CODE-01] <Short Finding Title>
* **Severity:** `P0` | `P1` | `P2`
* **Category:** `MAINTAINABILITY CRITICAL` | `TECH DEBT` | `STYLE INFO`
* **Location:** `file_path:line_number` or `function_name()` / `ClassName`
* **Roadmap Task Mapping:** `TASK-P0-XX` | `TASK-P1-XX` | `TASK-P2-XX`

#### Root Cause Analysis & Maintainability Impact
*Explanation of the issue (e.g., excessive branching, duplicated logic, hidden side effect) and why it increases the cost or risk of future changes.*

#### Current Code Snippet
```syntax
// Current problematic code
```

#### Refactored Snippet
```syntax
// Minimal, behavior-preserving refactor
```

---

## Verification Checklist
- [ ] Confirm the refactor preserves existing behavior (no functional change unless explicitly required).
- [ ] Re-run existing unit tests for the affected module.
- [ ] Confirm complexity/duplication metrics improved where tooling is available.
