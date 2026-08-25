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

documentation_missing_outputs() {
    local documentation_dir="$1"
    local document_name
    local -a required_documents=(
        "ARCHITECTURE.md"
        "ADMIN_GUIDE.md"
        "USER_GUIDE.md"
        "API_REF.md"
    )

    for document_name in "${required_documents[@]}"; do
        if [[ ! -f "${documentation_dir}/${document_name}" || ! -s "${documentation_dir}/${document_name}" ]]; then
            printf '%s\n' "$document_name"
        fi
    done
}

documentation_output_is_valid() {
    local documentation_dir="$1"
    local document_name

    while IFS= read -r document_name; do
        echo "Documentation output is missing or empty: ${document_name}" >&2
        return 1
    done < <(documentation_missing_outputs "$documentation_dir")
}