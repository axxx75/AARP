#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_DIR}/scripts/documentation_helpers.sh"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

mkdir -p "${TEMP_DIR}/repository/doc" "${TEMP_DIR}/repository/docs"
[[ "$(find_documentation_dir "${TEMP_DIR}/repository")" == "${TEMP_DIR}/repository/docs" ]] || {
    echo "Expected docs/ to be the preferred documentation directory." >&2
    exit 1
}

OUTPUT_DIR="${TEMP_DIR}/documentation"
mkdir -p "$OUTPUT_DIR"

cat > "${OUTPUT_DIR}/ARCHITECTURE.md" <<'EOF'
# Architecture
## Evidence classification
### Verified
Bash scripts orchestrate the repository.
### Inferred
No architecture inference is required for this fixture.
### Not verifiable
No deployment system is present in this fixture.
## System overview
The system runs a command-line workflow.
## Components and dependencies
The orchestrator coordinates prompts and templates.
## Data and control flow
Reports move from agents to the review workspace.
## External integrations
No external integration was verified.
## Constraints and open questions
The fixture has no additional constraints.
EOF

cat > "${OUTPUT_DIR}/ADMIN_GUIDE.md" <<'EOF'
# Administrator Guide
## Evidence classification
### Verified
The project uses Bash.
### Inferred
No additional setup inference is required for this fixture.
### Not verifiable
No backup service is present in this fixture.
## Setup and prerequisites
Install Bash and Git.
## Configuration and environment
Set model variables when required.
## Logging and observability
Review the generated logs.
## Operations and recovery
Rerun the command after resolving errors.
## Security considerations
No security configuration is present in this fixture.
EOF

cat > "${OUTPUT_DIR}/USER_GUIDE.md" <<'EOF'
# User Guide
## Evidence classification
### Verified
The workflow accepts a target.
### Inferred
No additional workflow inference is required for this fixture.
### Not verifiable
No support channel is present in this fixture.
## Getting started
Run the orchestrator with a target.
## Common workflows
Review the generated reports.
## Troubleshooting
Check logs after a failure.
## Support boundaries
The fixture does not define a support policy.
EOF

cat > "${OUTPUT_DIR}/API_REF.md" <<'EOF'
# API Reference
## Evidence classification
### Verified
No HTTP API was found.
### Inferred
No additional interface inference is required for this fixture.
### Not verifiable
No compatibility policy is present in this fixture.
## Interfaces
The command-line interface is the supported interface.
## Authentication and errors
No API authentication flow was verified.
## Examples
Run the documented command.
## Compatibility notes
No compatibility version was verified.
EOF

documentation_output_is_valid "$OUTPUT_DIR" || {
    echo "Expected a valid documentation bundle." >&2
    exit 1
}

sed -i '/No architecture inference is required for this fixture./d' "${OUTPUT_DIR}/ARCHITECTURE.md"
if documentation_output_is_valid "$OUTPUT_DIR" >/dev/null 2>&1; then
    echo "Expected an empty evidence classification to invalidate the documentation bundle." >&2
    exit 1
fi
sed -i '/### Inferred/a No architecture inference is required for this fixture.' "${OUTPUT_DIR}/ARCHITECTURE.md"

sed -i '/The system runs a command-line workflow./d' "${OUTPUT_DIR}/ARCHITECTURE.md"
if documentation_output_is_valid "$OUTPUT_DIR" >/dev/null 2>&1; then
    echo "Expected an empty required section to invalidate the documentation bundle." >&2
    exit 1
fi
sed -i '/## System overview/a The system runs a command-line workflow.' "${OUTPUT_DIR}/ARCHITECTURE.md"

printf '\n[Describe the service]\n' >> "${OUTPUT_DIR}/ARCHITECTURE.md"
if documentation_output_is_valid "$OUTPUT_DIR" >/dev/null 2>&1; then
    echo "Expected a template placeholder to invalidate the documentation bundle." >&2
    exit 1
fi

sed -i '/\[Describe the service\]/d' "${OUTPUT_DIR}/ARCHITECTURE.md"
sed -i '/### Inferred/d' "${OUTPUT_DIR}/ARCHITECTURE.md"
if documentation_output_is_valid "$OUTPUT_DIR" >/dev/null 2>&1; then
    echo "Expected missing evidence classification to invalidate the documentation bundle." >&2
    exit 1
fi

echo "Documentation helper fixtures passed."