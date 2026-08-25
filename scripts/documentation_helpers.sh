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


documentation_output_is_valid() {
    local documentation_dir="$1"
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
}