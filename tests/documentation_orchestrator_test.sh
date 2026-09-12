#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
FAKE_BIN="${TEMP_DIR}/bin"
FAKE_LOG="${TEMP_DIR}/openclaude.log"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "$FAKE_BIN"
cat > "${FAKE_BIN}/openclaude" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf 'documentation-agent-called\n' >> "$FAKE_OPENCLAUDE_LOG"
mkdir -p "$AARP_DOCUMENTATION_OUTPUT_DIR"

if [[ "${FAKE_DOCUMENTATION_MODE:-valid}" == "invalid" ]]; then
    printf '# Architecture\n' > "${AARP_DOCUMENTATION_OUTPUT_DIR}/ARCHITECTURE.md"
    exit 0
fi

cat > "${AARP_DOCUMENTATION_OUTPUT_DIR}/ARCHITECTURE.md" <<'DOC'
# Architecture
## Evidence classification
### Verified
The fixture contains a Git repository.
### Inferred
No additional architecture inference is required.
### Not verifiable
No deployment environment is present.
## System overview
The fixture is a minimal repository.
## Components and dependencies
Git is the only verified dependency.
## Data and control flow
No application data flow was verified.
## External integrations
No external integrations were verified.
## Constraints and open questions
The fixture intentionally contains no application code.
DOC

cat > "${AARP_DOCUMENTATION_OUTPUT_DIR}/ADMIN_GUIDE.md" <<'DOC'
# Administrator Guide
## Evidence classification
### Verified
Git is required for the fixture.
### Inferred
No additional setup inference is required.
### Not verifiable
No backup process is present.
## Setup and prerequisites
Install Git.
## Configuration and environment
No environment configuration was verified.
## Logging and observability
No logging integration was verified.
## Operations and recovery
Recreate the fixture if it is removed.
## Security considerations
No security configuration was verified.
DOC

cat > "${AARP_DOCUMENTATION_OUTPUT_DIR}/USER_GUIDE.md" <<'DOC'
# User Guide
## Evidence classification
### Verified
The repository can be inspected by AARP.
### Inferred
No additional user workflow inference is required.
### Not verifiable
No support channel is present.
## Getting started
Run AARP with the repository target.
## Common workflows
Review the generated documentation bundle.
## Troubleshooting
Inspect the generated logs after failures.
## Support boundaries
The fixture has no support policy.
DOC

if [[ "${FAKE_DOCUMENTATION_MODE:-valid}" == "missing-api-first" ]] &&
    [[ "$(wc -l < "$FAKE_OPENCLAUDE_LOG")" -eq 1 ]]; then
    exit 0
fi

cat > "${AARP_DOCUMENTATION_OUTPUT_DIR}/API_REF.md" <<'DOC'
# API Reference
## Evidence classification
### Verified
No API or CLI was verified in the fixture.
### Inferred
No additional interface inference is required.
### Not verifiable
No compatibility policy is present.
## Interfaces
No supported interface was verified.
## Authentication and errors
No authentication flow was verified.
## Examples
No interface example is available.
## Compatibility notes
No compatibility version was verified.
DOC
EOF
chmod +x "${FAKE_BIN}/openclaude"

create_target() {
    local target_dir="$1"
    mkdir -p "$target_dir"
    git init -q -b main "$target_dir"
    git -C "$target_dir" config user.name "AARP test"
    git -C "$target_dir" config user.email "test@example.invalid"
    printf '# Fixture\n' > "${target_dir}/README.md"
    git -C "$target_dir" add README.md
    git -C "$target_dir" commit -qm "Initial fixture"
}

run_only_doc() {
    local target_dir="$1"
    local review_dir="$2"
    local input="$3"
    local mode="${4:-valid}"

    printf '%b' "$input" | \
        PATH="${FAKE_BIN}:${PATH}" \
        FAKE_OPENCLAUDE_LOG="$FAKE_LOG" \
        FAKE_DOCUMENTATION_MODE="$mode" \
        bash "${PROJECT_DIR}/scripts/orchestrator.sh" \
            --target "$target_dir" \
            --review-dir "$review_dir" \
            --only-doc
}

# Declining the initial prompt must not invoke the agent or change the target.
DECLINED_TARGET="${TEMP_DIR}/declined-target"
create_target "$DECLINED_TARGET"
rm -f "$FAKE_LOG"
run_only_doc "$DECLINED_TARGET" "${TEMP_DIR}/declined-review" "n\n"
[[ ! -e "${DECLINED_TARGET}/docs" ]] || {
    echo "Declining documentation creation changed the target." >&2
    exit 1
}
[[ ! -e "$FAKE_LOG" ]] || {
    echo "Documentation agent ran after the creation prompt was declined." >&2
    exit 1
}

# Accepting generation but declining application produces staging only.
STAGED_TARGET="${TEMP_DIR}/staged-target"
STAGED_REVIEW="${TEMP_DIR}/staged-review"
create_target "$STAGED_TARGET"
run_only_doc "$STAGED_TARGET" "$STAGED_REVIEW" "s\nn\n"
[[ -f "${STAGED_REVIEW}/reports/documentation/ARCHITECTURE.md" ]] || {
    echo "Expected a staged documentation bundle." >&2
    exit 1
}
[[ ! -e "${STAGED_TARGET}/docs" ]] || {
    echo "Declining documentation application changed the target." >&2
    exit 1
}

# A malformed bundle must fail before a branch or target documentation is made.
INVALID_TARGET="${TEMP_DIR}/invalid-target"
create_target "$INVALID_TARGET"
if run_only_doc "$INVALID_TARGET" "${TEMP_DIR}/invalid-review" "s\n" "invalid"; then
    echo "Expected invalid documentation output to stop the command." >&2
    exit 1
fi
[[ ! -e "${INVALID_TARGET}/docs" ]] || {
    echo "Invalid documentation output changed the target." >&2
    exit 1
}

# A partial first response is resumed for each missing document.
RESUMED_TARGET="${TEMP_DIR}/resumed-target"
RESUMED_REVIEW="${TEMP_DIR}/resumed-review"
create_target "$RESUMED_TARGET"
rm -f "$FAKE_LOG"
run_only_doc "$RESUMED_TARGET" "$RESUMED_REVIEW" "s\nn\n" "missing-api-first"
[[ -s "${RESUMED_REVIEW}/reports/documentation/API_REF.md" ]] || {
    echo "Expected a retry to create the missing API reference." >&2
    exit 1
}
[[ "$(wc -l < "$FAKE_LOG")" -eq 2 ]] || {
    echo "Expected exactly one targeted documentation retry." >&2
    exit 1
}

# Applying a bundle creates a separate documentation branch and restores main.
BRANCH_TARGET="${TEMP_DIR}/branch-target"
BRANCH_REVIEW="${TEMP_DIR}/branch-review"
create_target "$BRANCH_TARGET"
mkdir -p "${BRANCH_TARGET}/docs"
printf 'Existing documentation\n' > "${BRANCH_TARGET}/docs/existing.md"
git -C "$BRANCH_TARGET" add docs/existing.md
git -C "$BRANCH_TARGET" commit -qm "Add existing docs"
run_only_doc "$BRANCH_TARGET" "$BRANCH_REVIEW" "s\n"
[[ "$(git -C "$BRANCH_TARGET" branch --show-current)" == "main" ]] || {
    echo "Documentation preparation did not restore the target branch." >&2
    exit 1
}
DOCUMENTATION_BRANCH="$(git -C "$BRANCH_TARGET" branch --format='%(refname:short)' | grep '^docs/documentation-' | head -n 1)"
[[ -n "$DOCUMENTATION_BRANCH" ]] || {
    echo "Expected an isolated documentation branch." >&2
    exit 1
}
git -C "$BRANCH_TARGET" show "${DOCUMENTATION_BRANCH}:docs/ARCHITECTURE.md" >/dev/null || {
    echo "Expected the documentation branch to contain the generated architecture guide." >&2
    exit 1
}

echo "Documentation orchestrator fixtures passed."