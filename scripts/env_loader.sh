#!/usr/bin/env bash

aarp_load_env() {
    local project_dir="$1"
    local env_file="${AARP_ENV_FILE:-${project_dir}/.env}"
    local variable_declaration
    local variable_name
    local allexport_was_enabled=false
    local -a runtime_variables=(
        OPENCLAUDE_PROVIDER
        MODEL_GENERAL
        MODEL_REASONING
        MODEL_DOCUMENTATION
        MODEL_REGRESSION
        CLAUDE_CODE_OPENAI_CONTEXT_WINDOWS
        CLAUDE_CODE_OPENAI_MAX_OUTPUT_TOKENS
        OPENAI_TEMPERATURE
        OPENROUTER_TIMEOUT
        OPENROUTER_MAX_RETRIES
        NODE_NO_WARNINGS
        DISABLE_TELEMETRY
        CLAUDE_CODE_DISABLE_BANNER
    )
    declare -A values_before=()
    declare -A variables_set_before=()

    if [[ ! -f "$env_file" ]]; then
        return 0
    fi

    # Preserve supported values exported by the caller. They take precedence
    # over the local .env file.
    for variable_name in "${runtime_variables[@]}"; do
        variable_declaration="$(declare -p "$variable_name" 2>/dev/null || true)"
        if [[ "$variable_declaration" =~ ^declare\ -[^[:space:]]*x ]]; then
            variables_set_before["$variable_name"]=1
            values_before["$variable_name"]="${!variable_name}"
        fi
    done

    [[ "$-" == *a* ]] && allexport_was_enabled=true

    set -a
    if ! source "$env_file"; then
        [[ "$allexport_was_enabled" == true ]] || set +a
        echo "Unable to load AARP environment file: ${env_file}" >&2
        return 1
    fi
    [[ "$allexport_was_enabled" == true ]] || set +a

    for variable_name in "${runtime_variables[@]}"; do
        if [[ -n "${variables_set_before[$variable_name]:-}" ]]; then
            printf -v "$variable_name" '%s' "${values_before[$variable_name]}"
            export "$variable_name"
        fi
    done

    echo "Loaded AARP environment file: ${env_file}"
}