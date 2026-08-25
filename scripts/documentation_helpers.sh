#!/usr/bin/env bash

# Return the first supported documentation directory in a repository snapshot.
find_documentation_dir() {
    local repository_dir="$1"
    local candidate

    for candidate in docs doc documents; do
        if [[ -d "${repository_dir}/${candidate}" ]]; then
            printf '%s\n' "${repository_dir}/${candidate}"
            return 0
        fi
    done

    return 1
}

documentation_section_has_content() {
    local document_path="$1"
    local heading="$2"
    local heading_prefix="${heading%%[^#]*}"
    local heading_level="${#heading_prefix}"

    awk -v heading="$heading" -v heading_level="$heading_level" '
        function current_heading_level(line) {
            if (match(line, /^#+/)) {
                return RLENGTH
            }
            return 0
        }
        $0 == heading {
            found = 1
            next
        }
        found {
            current_level = current_heading_level($0)
            if (current_level > 0 && current_level <= heading_level) {
                exit
            }
            if ($0 !~ /^[[:space:]]*$/) {
                content = 1
            }
        }
        END {
            exit !(found && content)
        }
    ' "$document_path"
}

documentation_sections_have_content() {
    local document_path="$1"
    shift
    local heading

    for heading in "$@"; do
        if ! documentation_section_has_content "$document_path" "$heading"; then
            echo "Documentation section is missing content: $(basename "$document_path") — ${heading}" >&2
            return 1
        fi
    done
}

documentation_output_is_valid() {
    local documentation_dir="$1"
    local document_path
    local document_name
    local -a required_documents=(
        "ARCHITECTURE.md"
        "ADMIN_GUIDE.md"
        "USER_GUIDE.md"
        "API_REF.md"
    )

    for document_name in "${required_documents[@]}"; do
        document_path="${documentation_dir}/${document_name}"
        if [[ ! -f "$document_path" || ! -s "$document_path" ]]; then
            echo "Documentation output is missing or empty: ${document_name}" >&2
            return 1
        fi
    done

    grep -Fq "# Architecture" "${documentation_dir}/ARCHITECTURE.md" &&
        grep -Fq "## Evidence classification" "${documentation_dir}/ARCHITECTURE.md" &&
        grep -Fq "### Verified" "${documentation_dir}/ARCHITECTURE.md" &&
        grep -Fq "### Inferred" "${documentation_dir}/ARCHITECTURE.md" &&
        grep -Fq "### Not verifiable" "${documentation_dir}/ARCHITECTURE.md" &&
        grep -Fq "## System overview" "${documentation_dir}/ARCHITECTURE.md" &&
        grep -Fq "## Components and dependencies" "${documentation_dir}/ARCHITECTURE.md" &&
        grep -Fq "## Data and control flow" "${documentation_dir}/ARCHITECTURE.md" &&
        grep -Fq "## External integrations" "${documentation_dir}/ARCHITECTURE.md" &&
        grep -Fq "## Constraints and open questions" "${documentation_dir}/ARCHITECTURE.md" ||
        { echo "ARCHITECTURE.md does not match the Documentation Architect contract." >&2; return 1; }
    documentation_sections_have_content "${documentation_dir}/ARCHITECTURE.md" \
        "## Evidence classification" \
        "### Verified" \
        "### Inferred" \
        "### Not verifiable" \
        "## System overview" \
        "## Components and dependencies" \
        "## Data and control flow" \
        "## External integrations" \
        "## Constraints and open questions" || return 1

    grep -Fq "# Administrator Guide" "${documentation_dir}/ADMIN_GUIDE.md" &&
        grep -Fq "## Evidence classification" "${documentation_dir}/ADMIN_GUIDE.md" &&
        grep -Fq "### Verified" "${documentation_dir}/ADMIN_GUIDE.md" &&
        grep -Fq "### Inferred" "${documentation_dir}/ADMIN_GUIDE.md" &&
        grep -Fq "### Not verifiable" "${documentation_dir}/ADMIN_GUIDE.md" &&
        grep -Fq "## Setup and prerequisites" "${documentation_dir}/ADMIN_GUIDE.md" &&
        grep -Fq "## Configuration and environment" "${documentation_dir}/ADMIN_GUIDE.md" &&
        grep -Fq "## Logging and observability" "${documentation_dir}/ADMIN_GUIDE.md" &&
        grep -Fq "## Operations and recovery" "${documentation_dir}/ADMIN_GUIDE.md" &&
        grep -Fq "## Security considerations" "${documentation_dir}/ADMIN_GUIDE.md" ||
        { echo "ADMIN_GUIDE.md does not match the Documentation Architect contract." >&2; return 1; }
    documentation_sections_have_content "${documentation_dir}/ADMIN_GUIDE.md" \
        "## Evidence classification" \
        "### Verified" \
        "### Inferred" \
        "### Not verifiable" \
        "## Setup and prerequisites" \
        "## Configuration and environment" \
        "## Logging and observability" \
        "## Operations and recovery" \
        "## Security considerations" || return 1

    grep -Fq "# User Guide" "${documentation_dir}/USER_GUIDE.md" &&
        grep -Fq "## Evidence classification" "${documentation_dir}/USER_GUIDE.md" &&
        grep -Fq "### Verified" "${documentation_dir}/USER_GUIDE.md" &&
        grep -Fq "### Inferred" "${documentation_dir}/USER_GUIDE.md" &&
        grep -Fq "### Not verifiable" "${documentation_dir}/USER_GUIDE.md" &&
        grep -Fq "## Getting started" "${documentation_dir}/USER_GUIDE.md" &&
        grep -Fq "## Common workflows" "${documentation_dir}/USER_GUIDE.md" &&
        grep -Fq "## Troubleshooting" "${documentation_dir}/USER_GUIDE.md" &&
        grep -Fq "## Support boundaries" "${documentation_dir}/USER_GUIDE.md" ||
        { echo "USER_GUIDE.md does not match the Documentation Architect contract." >&2; return 1; }
    documentation_sections_have_content "${documentation_dir}/USER_GUIDE.md" \
        "## Evidence classification" \
        "### Verified" \
        "### Inferred" \
        "### Not verifiable" \
        "## Getting started" \
        "## Common workflows" \
        "## Troubleshooting" \
        "## Support boundaries" || return 1

    grep -Fq "# API Reference" "${documentation_dir}/API_REF.md" &&
        grep -Fq "## Evidence classification" "${documentation_dir}/API_REF.md" &&
        grep -Fq "### Verified" "${documentation_dir}/API_REF.md" &&
        grep -Fq "### Inferred" "${documentation_dir}/API_REF.md" &&
        grep -Fq "### Not verifiable" "${documentation_dir}/API_REF.md" &&
        grep -Fq "## Interfaces" "${documentation_dir}/API_REF.md" &&
        grep -Fq "## Authentication and errors" "${documentation_dir}/API_REF.md" &&
        grep -Fq "## Examples" "${documentation_dir}/API_REF.md" &&
        grep -Fq "## Compatibility notes" "${documentation_dir}/API_REF.md" ||
        { echo "API_REF.md does not match the Documentation Architect contract." >&2; return 1; }
    documentation_sections_have_content "${documentation_dir}/API_REF.md" \
        "## Evidence classification" \
        "### Verified" \
        "### Inferred" \
        "### Not verifiable" \
        "## Interfaces" \
        "## Authentication and errors" \
        "## Examples" \
        "## Compatibility notes" || return 1

    if grep -R -nE '\[(Describe|List|Explain|Project Name|TODO|TBD)' "$documentation_dir" >/dev/null; then
        echo "Documentation output still contains template placeholders." >&2
        return 1
    fi
}