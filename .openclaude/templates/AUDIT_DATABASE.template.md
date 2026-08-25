# Database & Storage Audit Report: [Project Name / Module]

* **Date:** YYYY-MM-DD
* **Auditor Agent:** Lead Database Administrator & Storage Architect
* **Target Commit / Branch:** `[commit-hash-or-branch]`
* **Focus Areas:** Query Efficiency, Concurrency, Schema Integrity, IOPS / Footprint

---

## Executive Database Summary

| Severity Priority | Performance Critical | Optimization | Schema / Info | Total Issues |
| :--- | :---: | :---: | :---: | :---: |
| **P0 (Critical)** | 0 | 0 | 0 | 0 |
| **P1 (High)**     | 0 | 0 | 0 | 0 |
| **P2 (Medium)**   | 0 | 0 | 0 | 0 |

---

## Detailed Performance & Storage Findings

### [DB-01] <Short Finding Title>
* **Severity:** `P0` | `P1` | `P2`
* **Category:** `PERFORMANCE CRITICAL` | `OPTIMIZATION` | `SCHEMA INFO`
* **Location:** `file_path:line_number` or `function_name()`
* **Roadmap Task Mapping:** `TASK-P0-XX` | `TASK-P1-XX` | `TASK-P2-XX`

#### Root Cause Analysis & Resource Impact
*Explanation of the issue (e.g., N+1 query, non-sargable WHERE clause, unindexed foreign key) and estimated CPU/RAM/IOPS footprint.*

#### Current Query / Code Snippet
```sql
-- Current inefficient query or ORM snippet
```

#### Refactored Query / Migration / Index Fix
```sql
-- Optimized SQL, migration script, or ORM update
```

---

## Verification Checklist
- [ ] Validate query execution plan (`EXPLAIN ANALYZE`).
- [ ] Confirm lock contention and transaction duration are within acceptable thresholds.
- [ ] Update migration scripts / ORM models.
