#!/usr/bin/env bash

# Temporary checkpoint policy:
# accept every regular, non-empty report and regenerate only missing or empty
# files. Content validation can be added here later without changing callers.
validate_report() {
    local report_path="$1"
    local report_label="$2"
    local template_path="$3"

    if [[ ! -f "$report_path" || ! -s "$report_path" ]]; then
        echo -e "${YELLOW:-}⚠ [REGENERATE] ${report_label} è mancante o vuoto; verrà rigenerato usando ${template_path}.${NC:-}" >&2
        return 1
    fi

    return 0
}