#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_DIR}/scripts/roadmap_helpers.sh"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

ROADMAP_REPORT="${TEMP_DIR}/ROADMAP.md"

cat > "$ROADMAP_REPORT" <<'EOF'
# Target Release: release/v2.0.0
## 🛠️ P2 Priority — Code Optimizations & Tech Debt
- [ ] **[TASK-P2-01]** Remove duplicated cache work
  * **Effort:** L
## ⚡ P1 Priority — Core Features & Architecture Improvements
- [ ] **[TASK-P1-01]** Add audit history export
  * **Effort:** S
- [ ] **[TASK-P1-010]** A distinct task that shares a prefix
  * **Effort:** M
## 🚨 P0 Priority — Critical Blockers & Vulnerabilities
- [ ] **[TASK-P0-01]** SQL injection in the query helper
  * **Effort:** M
## 📊 Status Tracking Checklist
| Task ID | Severity | Assigned Agent | Branch | Status | HITL Approval |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TASK-P0-01** | `P0 CRITICAL` | AppSec | `fix/p0-sqli` | Pending | `[ Required ]` |
| **TASK-P1-01** | `P1 HIGH` | Architect | `feat/p1-export` | Pending | `[ Required ]` |
| **TASK-P1-010** | `P1 HIGH` | Architect | `feat/p1-prefix-collision` | Pending | `[ Required ]` |
| **TASK-P2-01** | `P2 MEDIUM` | UX/UI Lead | `refactor/p2-cache` | Pending | `[ Required ]` |
EOF

assert_preview() {
    local expected_id="$1"
    local expected_priority="$2"
    local expected_prefix="$3"
    local expected_effort="$4"
    local skipped_ids="${5:-}"
    local preview
    local task_id
    local priority
    local prefix

    preview="$(roadmap_next_task_preview "$skipped_ids")"
    task_id="$(roadmap_task_id_from_preview "$preview")"
    priority="$(roadmap_task_priority_from_id "$task_id")"
    prefix="$(roadmap_task_branch_prefix "$priority")"

    [[ "$task_id" == "$expected_id" ]] || {
        echo "Expected ${expected_id}, got: ${task_id}" >&2
        exit 1
    }
    [[ "$priority" == "$expected_priority" ]] || {
        echo "Expected priority ${expected_priority}, got: ${priority}" >&2
        exit 1
    }
    [[ "$prefix" == "$expected_prefix" ]] || {
        echo "Expected branch prefix ${expected_prefix}, got: ${prefix}" >&2
        exit 1
    }
    [[ "$preview" == *"Effort"* && "$preview" == *"$expected_effort"* ]] || {
        echo "Expected effort ${expected_effort} in the preview." >&2
        exit 1
    }
}

assert_preview "TASK-P0-01" "P0" "fix/p0-" "M"
assert_preview "TASK-P1-01" "P1" "feat/p1-" "S" "TASK-P0-01"
assert_preview "TASK-P2-01" "P2" "refactor/p2-" "L" "TASK-P0-01,TASK-P1-01,TASK-P1-010"
mark_roadmap_task_merged "TASK-P0-01"
grep -q -- '- \[x\] \*\*\[TASK-P0-01\]' "$ROADMAP_REPORT" || {
    echo "Expected the P0 checkbox to be marked." >&2
    exit 1
}
grep -q '| \*\*TASK-P0-01\*\* | `P0 CRITICAL` | AppSec | `fix/p0-sqli` | Merged |' "$ROADMAP_REPORT" || {
    echo "Expected the P0 status to be marked as Merged." >&2
    exit 1
}

assert_preview "TASK-P1-01" "P1" "feat/p1-" "S"
mark_roadmap_task_merged "TASK-P1-01"
grep -q -- '- \[x\] \*\*\[TASK-P1-01\]' "$ROADMAP_REPORT" || {
    echo "Expected the P1 checkbox to be marked." >&2
    exit 1
}
grep -q '| \*\*TASK-P1-01\*\* | `P1 HIGH` | Architect | `feat/p1-export` | Merged |' "$ROADMAP_REPORT" || {
    echo "Expected the P1 status to be marked as Merged." >&2
    exit 1
}
grep -q -- '- \[ \] \*\*\[TASK-P1-010\]' "$ROADMAP_REPORT" || {
    echo "Expected the prefix-sharing P1 task to remain unchecked." >&2
    exit 1
}
grep -q '| \*\*TASK-P1-010\*\* | `P1 HIGH` | Architect | `feat/p1-prefix-collision` | Pending |' "$ROADMAP_REPORT" || {
    echo "Expected the prefix-sharing P1 status to remain unchanged." >&2
    exit 1
}

mark_roadmap_task_merged "TASK-P1-010"
assert_preview "TASK-P2-01" "P2" "refactor/p2-" "L"
marked_once="$(cat "$ROADMAP_REPORT")"
mark_roadmap_task_merged "TASK-P2-01"
marked_twice="$(cat "$ROADMAP_REPORT")"
[[ "$marked_once" != "$marked_twice" ]] || {
    echo "Expected the P2 roadmap record to change on merge." >&2
    exit 1
}
after_p2_merge="$(cat "$ROADMAP_REPORT")"
mark_roadmap_task_merged "TASK-P2-01"
[[ "$after_p2_merge" == "$(cat "$ROADMAP_REPORT")" ]] || {
    echo "Expected roadmap marking to be idempotent." >&2
    exit 1
}
if roadmap_next_task_preview >/dev/null 2>&1; then
    echo "Expected no open P0, P1, or P2 task." >&2
    exit 1
fi

cat > "$ROADMAP_REPORT" <<'EOF'
# Target Release: release/v2.0.0
## 🚨 P0 Priority — Critical Blockers & Vulnerabilities
The P0 details are tracked in the status table.
## 📊 Status Tracking Checklist
| Task ID | Severity | Assigned Agent | Branch | Status | HITL Approval |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TASK-P2-99** | `P2 MEDIUM` | UX/UI Lead | `refactor/p2-cleanup` | Pending | `[ Required ]` |
EOF

fallback_preview="$(roadmap_next_task_preview)"
[[ "$fallback_preview" == *"TASK-P2-99"* ]] || {
    echo "Expected status-table fallback preview." >&2
    exit 1
}

echo "Roadmap helper fixtures passed."