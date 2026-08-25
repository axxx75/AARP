# AppSec Audit Report: [Project Name / Module]

* **Date:** YYYY-MM-DD
* **Auditor Agent:** Principal Application Security Engineer
* **Target Commit / Branch:** `[commit-hash-or-branch]`
* **Compliance Target:** OWASP Top 10, CWE Standards, Zero Trust

---

## Executive Security Summary

| Severity | Total Found | P0 Blockers | Remediated | Pending |
| :--- | :---: | :---: | :---: | :---: |
| **CRITICAL** | 0 | 0 | 0 | 0 |
| **HIGH** | 0 | 0 | 0 | 0 |
| **MEDIUM** | 0 | 0 | 0 | 0 |
| **LOW** | 0 | 0 | 0 | 0 |

---

## Detailed Vulnerability Findings

### [VULN-01] <Short Vulnerability Title>
* **Severity:** `CRITICAL` | `HIGH` | `MEDIUM` | `LOW`
* **CWE ID:** CWE-XXX (e.g., CWE-89)
* **Location:** `file_path:line_number`
* **Roadmap Task Mapping:** `TASK-P0-XX` | `TASK-P1-XX` | `TASK-P2-XX`

#### Risk & Exploitability
*Concise analysis of how an attacker could exploit this flaw, attack vector involved, and potential business/system impact.*

#### Vulnerable Code Snippet
```syntax
// Vulnerable code block
```

#### Remediation & Refactored Code
```syntax
// Secure refactored code block
```

---

## Security Verification & Next Steps
- [ ] Verify refactored code against unit / integration security tests.
- [ ] Ensure secrets scan passes clean (no hardcoded tokens/keys).
- [ ] Submit PR for Human-in-the-Loop (HITL) review.
