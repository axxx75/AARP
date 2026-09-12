# GIT_AI_WORKFLOW.md: Git & Human-in-the-Loop (HITL) Workflow

This document defines the software engineering rules and Git lifecycle for human developers and OpenClaude AI agents operating on this repository.

---

## 1. The Isolation Rule (One Task = One Branch)

**Direct commits or refactoring on `main` / `master` are strictly prohibited.**

Every task defined in `ROADMAP.md` must be executed within an isolated branch using the following hierarchy:

* **`main` (Production):** Contains strictly tested, approved, and tagged production code (`vX.Y.Z`). This is a protected branch: **no direct commits are allowed**.
* **`release/vX.Y.Z` (Release Integration):** The staging/integration environment for the target release. This is where `ROADMAP.md` is initialized by the orchestrator and where approved task branches merge prior to final release.
* **Atomic Feature/Fix Branches (Ephemeral Task Branches):** Short-lived branches created off `release/vX.Y.Z` for specific tasks and deleted immediately after merging. Must adhere to strict naming conventions:
  * `fix/p0-<task-name>`: Critical bugs, security vulnerabilities, or operational blockers (P0 priority).
  * `feat/p1-<feature-name>`: Core feature developments or major architectural improvements (P1 priority).
  * `refactor/p2-<task-name>`: Code optimization, tech debt remediation, or non-critical tweaks (P2 priority).

During phase 4, the orchestrator previews the first unresolved roadmap task in
P0 → P1 → P2 order and requires task-specific human confirmation before
starting an agent. The agent updates only the target checkout; the
orchestrator can publish the task branch for isolated testing, then marks that
task as merged in the review roadmap after, and only after, a successful
merge.

The diagram below illustrates a P0 branch; P1 and P2 tasks follow the same
cycle with their respective `feat/p1-...` and `refactor/p2-...` prefixes.
The operator may start the displayed task, skip it for the current run without
changing the roadmap, or exit; an exited or skipped task is available again on
the next run. A tested task branch can be kept or discarded independently
before deciding whether to merge it into the release branch.

---

## 2. The 5-Phase Operational Cycle

```mermaid
gitGraph
    commit id: "v1.0.0" tag: "v1.0.0"
    branch release/v1.1.0
    checkout release/v1.1.0
    commit id: "Init ROADMAP.md"
    branch fix/p0-1-sqli
    checkout fix/p0-1-sqli
    commit id: "Fix SQLi flaw"
    checkout release/v1.1.0
    merge fix/p0-1-sqli id: "PR Approved (HITL)"
    checkout main
    merge release/v1.1.0 id: "Tag v1.1.0" tag: "v1.1.0"
