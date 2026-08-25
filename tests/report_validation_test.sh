#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES_DIR="${PROJECT_DIR}/.openclaude/templates"
source "${PROJECT_DIR}/scripts/report_validation.sh"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

set_report_spec() {
    local report_kind="$1"

    case "$report_kind" in
        context)
            TEMPLATE_PATH="${TEMPLATES_DIR}/PROJECT_CONTEXT.template.md"
            REPORT_LABEL="PROJECT_CONTEXT.md"
            REQUIRED_MARKERS=(
                "# Project Context & Architectural Blueprint"
                "## 1. Tech Stack & Core Services"
                "## 2. Architecture & Data Flow"
                "## 3. Critical Path, Blind Spots & Technical Debt"
            )
            UNRESOLVED_PLACEHOLDER="[Identify the languages, runtimes, and versions]"
            ;;
        appsec)
            TEMPLATE_PATH="${TEMPLATES_DIR}/AUDIT_APPSEC.template.md"
            REPORT_LABEL="AUDIT_SECURITY.md"
            REQUIRED_MARKERS=(
                "# AppSec Audit Report:"
                "## Executive Security Summary"
                "## Detailed Vulnerability Findings"
                "## Security Verification & Next Steps"
            )
            UNRESOLVED_PLACEHOLDER="[Project Name / Module]"
            ;;
        database)
            TEMPLATE_PATH="${TEMPLATES_DIR}/AUDIT_DATABASE.template.md"
            REPORT_LABEL="AUDIT_DB.md"
            REQUIRED_MARKERS=(
                "# Database & Storage Audit Report:"
                "## Executive Database Summary"
                "## Detailed Performance & Storage Findings"
                "## Verification Checklist"
            )
            UNRESOLVED_PLACEHOLDER="[Project Name / Module]"
            ;;
        ux)
            TEMPLATE_PATH="${TEMPLATES_DIR}/AUDIT_UX_PERF.template.md"
            REPORT_LABEL="AUDIT_UX_UI.md"
            REQUIRED_MARKERS=(
                "# UX/UI & Front-End Performance Audit Report:"
                "## Executive UX & Performance Summary"
                "## Detailed Findings & Accessibility Audit"
                "## Verification Checklist"
            )
            UNRESOLVED_PLACEHOLDER="[Project Name / Module]"
            ;;
        roadmap)
            TEMPLATE_PATH="${TEMPLATES_DIR}/ROADMAP.template.md"
            REPORT_LABEL="ROADMAP.md"
            REQUIRED_MARKERS=(
                "# Target Release:"
                "## 🚨 P0 Priority — Critical Blockers & Vulnerabilities"
                "## ⚡ P1 Priority — Core Features & Architecture Improvements"
                "## 🛠️ P2 Priority — Code Optimizations & Tech Debt"
                "## 📊 Status Tracking Checklist"
            )
            UNRESOLVED_PLACEHOLDER="<Scope & Remediation>"
            ;;
    esac
}

assert_valid() {
    local fixture_path="$1"

    if ! validate_report "$fixture_path" "$REPORT_LABEL" "$TEMPLATE_PATH" "${REQUIRED_MARKERS[@]}" >/dev/null 2>&1; then
        echo "Expected a valid checkpoint: ${REPORT_LABEL}" >&2
        exit 1
    fi
}

assert_invalid() {
    local fixture_path="$1"

    if validate_report "$fixture_path" "$REPORT_LABEL" "$TEMPLATE_PATH" "${REQUIRED_MARKERS[@]}" >/dev/null 2>&1; then
        echo "Expected regeneration for ${REPORT_LABEL}: ${fixture_path}" >&2
        exit 1
    fi
}

assert_invalid_with_reason() {
    local fixture_path="$1"
    local expected_reason="$2"
    local output

    if output=$(validate_report "$fixture_path" "$REPORT_LABEL" "$TEMPLATE_PATH" "${REQUIRED_MARKERS[@]}" 2>&1); then
        echo "Expected regeneration for ${REPORT_LABEL}: ${fixture_path}" >&2
        exit 1
    fi

    if [[ "$output" != *"$expected_reason"* ]]; then
        echo "Expected validation reason for ${REPORT_LABEL}: ${expected_reason}" >&2
        exit 1
    fi
}

write_valid_fixture() {
    local report_kind="$1"
    local fixture_path="$2"

    case "$report_kind" in
        context)
            cat > "$fixture_path" <<'EOF'
# Project Context & Architectural Blueprint
## 1. Tech Stack & Core Services
- Runtime: Bash orchestration on Linux.
- Storage: Generated Markdown reports are kept in the repository root.
## 2. Architecture & Data Flow
- The orchestrator maps the project before starting specialist audits.
- Specialists write their audit files before roadmap synthesis begins.
## 3. Critical Path, Blind Spots & Technical Debt
- The resume gate is a critical path because it controls audit reuse.
- Automated fixtures cover reports that are incomplete or still templated.
EOF
            ;;
        appsec)
            cat > "$fixture_path" <<'EOF'
# AppSec Audit Report: AARP
* **Date:** 2026-08-24
* **Target Commit / Branch:** `main`
## Executive Security Summary
The review covered the orchestration entry points and report handling.
No exploitable weaknesses were identified in the reviewed shell flow.
## Detailed Vulnerability Findings
No security findings were identified after inspecting the report-resume path.
## Security Verification & Next Steps
- [x] Review completed.
EOF
            ;;
        database)
            cat > "$fixture_path" <<'EOF'
# Database & Storage Audit Report: AARP
* **Date:** 2026-08-24
* **Target Commit / Branch:** `main`
## Executive Database Summary
The repository does not define a database workload for this audit.
Storage behavior is limited to local Markdown report files.
## Detailed Performance & Storage Findings
No database findings were identified because no database integration is present.
## Verification Checklist
- [x] Storage review completed.
EOF
            ;;
        ux)
            cat > "$fixture_path" <<'EOF'
# UX/UI & Front-End Performance Audit Report: AARP
* **Date:** 2026-08-24
* **Target Commit / Branch:** `main`
## Executive UX & Performance Summary
The repository is a command-line workflow without rendered UI components.
No user-interface performance regressions were identified.
## Detailed Findings & Accessibility Audit
No UX findings were identified because the project has no browser interface.
## Verification Checklist
- [x] UX scope reviewed.
EOF
            ;;
        roadmap)
            cat > "$fixture_path" <<'EOF'
# Target Release: release/v2.0.0
## 🚨 P0 Priority — Critical Blockers & Vulnerabilities
No P0 tasks were identified by the completed audits.
The release can proceed without critical blockers.
Human review is still required before remediation begins.
## ⚡ P1 Priority — Core Features & Architecture Improvements
No P1 tasks were identified by the completed audits.
The current architecture requires no planned feature work.
Follow-up work can be scheduled after the next audit.
## 🛠️ P2 Priority — Code Optimizations & Tech Debt
No P2 tasks were identified by the completed audits.
The reported technical debt does not require a roadmap item.
The next review will reassess optimization opportunities.
## 📊 Status Tracking Checklist
No roadmap tasks are pending after this review.
The human-in-the-loop checkpoint remains required.
EOF
            ;;
    esac
}

write_roadmap_short_fixture() {
    local fixture_path="$1"

    cat > "$fixture_path" <<'EOF'
# Target Release: release/v2.0.0
## 🚨 P0 Priority — Critical Blockers & Vulnerabilities
No critical blockers were identified in the reviewed repository.
## ⚡ P1 Priority — Core Features & Architecture Improvements
The planned P1 work remains in the backlog.
## 🛠️ P2 Priority — Code Optimizations & Tech Debt
Minor cleanup is deferred to a later review.
## 📊 Status Tracking Checklist
Human approval is pending before remediation.
EOF
}

write_roadmap_missing_section_fixture() {
    local fixture_path="$1"

    cat > "$fixture_path" <<'EOF'
# Target Release: release/v2.0.0
## 🚨 P0 Priority — Critical Blockers & Vulnerabilities
No critical blockers were identified.
## ⚡ P1 Priority — Core Features & Architecture Improvements
No approved P1 work is currently tracked.
## 📊 Status Tracking Checklist
Human approval is pending before remediation.
EOF
}

write_roadmap_residual_template_fixture() {
    local fixture_path="$1"

    cat > "$fixture_path" <<'EOF'
# Target Release: release/vX.Y.Z
> Create isolated task branches from `release/vX.Y.Z`.
## 🚨 P0 Priority — Critical Blockers & Vulnerabilities
*Branch Prefix: `fix/p0-<task-name>`*
The audit identified one critical repository-specific blocker.
## ⚡ P1 Priority — Core Features & Architecture Improvements
*Branch Prefix: `feat/p1-<feature-name>`*
The audit identified one architectural improvement for the next release.
## 🛠️ P2 Priority — Code Optimizations & Tech Debt
*Branch Prefix: `refactor/p2-<task-name>`*
The audit identified one non-blocking maintenance item.
## 📊 Status Tracking Checklist
The listed tasks are pending human approval.
EOF
}

write_roadmap_alternative_title_fixture() {
    local fixture_path="$1"

    write_roadmap_residual_template_fixture "$fixture_path"
    sed -i '1c# SANForge Release Roadmap — release/v3.0.0' "$fixture_path"
}

write_database_no_scope_fixture() {
    local fixture_path="$1"

    cat > "$fixture_path" <<'EOF'
# Database & Storage Audit Report: AARP
* **Date:** 2026-08-24
* **Auditor Agent:** Lead Database Administrator & Storage Architect
* **Target Commit / Branch:** `main`
* **Focus Areas:** Query Efficiency, Concurrency, Schema Integrity, IOPS / Footprint
## Executive Database Summary
| Severity Priority | Performance Critical | Optimization | Schema / Info | Total Issues |
| :--- | :---: | :---: | :---: | :---: |
| **P0 (Critical)** | 0 | 0 | 0 | 0 |
| **P1 (High)**     | 0 | 0 | 0 | 0 |
| **P2 (Medium)**   | 0 | 0 | 0 | 0 |
No database or managed storage integration is present in the reviewed repository.
## Detailed Performance & Storage Findings
No database findings were identified because the repository has no database workload.
## Verification Checklist
- [x] Database and storage scope reviewed.
EOF
}

write_database_populated_summary_fixture() {
    local fixture_path="$1"

    cat > "$fixture_path" <<'EOF'
# Database & Storage Audit Report: AARP
* **Date:** 2026-08-24
* **Auditor Agent:** Lead Database Administrator & Storage Architect
* **Target Commit / Branch:** `main`
* **Focus Areas:** Query Efficiency, Concurrency, Schema Integrity, IOPS / Footprint
## Executive Database Summary
| Severity Priority | Performance Critical | Optimization | Schema / Info | Total Issues |
| :--- | :---: | :---: | :---: | :---: |
| **P0 (Critical)** | 0 | 0 | 0 | 0 |
| **P1 (High)**     | 0 | 1 | 0 | 1 |
| **P2 (Medium)**   | 0 | 0 | 1 | 1 |
## Detailed Performance & Storage Findings
### [DB-01] Missing index for dashboard query
* **Severity:** `P1`
* **Category:** `OPTIMIZATION`
* **Location:** `db_manager.py:42`
* **Roadmap Task Mapping:** `TASK-P1-01`
The dashboard query filters a growing history table without a supporting index.
### [DB-02] Retention policy needs verification
* **Severity:** `P2`
* **Category:** `SCHEMA INFO`
* **Location:** `db_manager.py:88`
* **Roadmap Task Mapping:** `TASK-P2-01`
The configured retention policy should be verified against production storage limits.
## Verification Checklist
- [x] Database and storage scope reviewed.
EOF
}

write_database_stale_summary_fixture() {
    local fixture_path="$1"

    write_database_populated_summary_fixture "$fixture_path"
    sed -i \
        -e 's/| \*\*P1 (High)\*\*     | 0 | 1 | 0 | 1 |/| **P1 (High)**     | 0 | 0 | 0 | 0 |/' \
        -e 's/| \*\*P2 (Medium)\*\*   | 0 | 0 | 1 | 1 |/| **P2 (Medium)**   | 0 | 0 | 0 | 0 |/' \
        "$fixture_path"
}

write_database_unstructured_summary_fixture() {
    local fixture_path="$1"

    cat > "$fixture_path" <<'EOF'
# Database & Storage Audit Report: SANForge
* **Date:** 2026-08-24
* **Target Commit / Branch:** `release/v3.0.0`
## Executive Database Summary
| Severity Priority | Performance Critical | Optimization | Schema / Info | Total Issues |
| :--- | :---: | :---: | :---: | :---: |
| **P0 (Critical)** | 0 | 0 | 0 | 0 |
| **P1 (High)**     | 0 | 0 | 0 | 0 |
| **P2 (Medium)**   | 0 | 0 | 0 | 0 |
## Detailed Performance & Storage Findings
### P1-01: collect_status schema recommendation
* **Severity:** `P0` | `P1` | `P2`
* **Category:** `PERFORMANCE CRITICAL` | `OPTIMIZATION` | `SCHEMA INFO`
* **Location:** `db_manager.py:201` or `function_name()`
* **Roadmap Task Mapping:** `TASK-P0-XX` | `TASK-P1-XX` | `TASK-P2-XX`
The table is correctly defined with a primary key; adding a uniqueness constraint is recommended.
### P2-01: UNION query optimization
* **Severity:** `P0` | `P1` | `P2`
* **Category:** `PERFORMANCE CRITICAL` | `OPTIMIZATION` | `SCHEMA INFO`
* **Location:** `db_manager.py:445-500` or `function_name()`
* **Roadmap Task Mapping:** `TASK-P0-XX` | `TASK-P1-XX` | `TASK-P2-XX`
The UNION query in get_known_vfids_by_switch() can be optimized to reduce repeated work.
## Verification Checklist
- [x] Database and storage scope reviewed.
EOF
}

for report_kind in context appsec database ux roadmap; do
    set_report_spec "$report_kind"
    fixture_path="${TEMP_DIR}/${report_kind}.md"

    rm -f "$fixture_path"
    assert_invalid "$fixture_path"

    : > "$fixture_path"
    assert_invalid "$fixture_path"

    cp "$TEMPLATE_PATH" "$fixture_path"
    assert_valid "$fixture_path"

    {
        printf '%s\n' "${REQUIRED_MARKERS[@]}"
        printf '%s\n' "Generated filler line one." "Generated filler line two." "Generated filler line three."
        printf '%s\n' "Generated filler line four." "Generated filler line five." "Generated filler line six."
    } > "$fixture_path"
    assert_valid "$fixture_path"

    write_valid_fixture "$report_kind" "$fixture_path"
    printf '\n%s\n' "$UNRESOLVED_PLACEHOLDER" >> "$fixture_path"
    assert_valid "$fixture_path"

    write_valid_fixture "$report_kind" "$fixture_path"
    assert_valid "$fixture_path"

    if [[ "$report_kind" == "database" ]]; then
        write_database_no_scope_fixture "$fixture_path"
        assert_valid "$fixture_path"

        write_database_populated_summary_fixture "$fixture_path"
        assert_valid "$fixture_path"

        write_database_stale_summary_fixture "$fixture_path"
        assert_valid "$fixture_path"

        write_database_unstructured_summary_fixture "$fixture_path"
        assert_valid "$fixture_path"
    elif [[ "$report_kind" == "roadmap" ]]; then
        write_roadmap_short_fixture "$fixture_path"
        assert_valid "$fixture_path"

        write_roadmap_residual_template_fixture "$fixture_path"
        assert_valid "$fixture_path"

        write_roadmap_alternative_title_fixture "$fixture_path"
        assert_valid "$fixture_path"

        write_roadmap_missing_section_fixture "$fixture_path"
        assert_valid "$fixture_path"
    fi
done

echo "Report validation fixtures passed."