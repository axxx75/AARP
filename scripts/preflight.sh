#!/usr/bin/env bash

aarp_print_configuration() {
    cat <<EOF
AARP runtime configuration
  Provider:      ${OPENCLAUDE_PROVIDER}
  General:       ${MODEL_GENERAL}
  Reasoning:     ${MODEL_REASONING}
  Documentation: ${MODEL_DOCUMENTATION}
  Regression:    ${MODEL_REGRESSION}
  Timeout:       ${OPENROUTER_TIMEOUT}s
  Retries:       ${OPENROUTER_MAX_RETRIES}
EOF
}

aarp_preflight() {
    local scope="${1:-orchestrator}"
    local command_name
    local -a missing_commands=()
    local -a required_commands=(bash git openclaude)

    if [[ "$scope" == "orchestrator" ]]; then
        required_commands+=(tar)
    fi

    if ((BASH_VERSINFO[0] < 4)); then
        echo "AARP requires Bash 4 or newer; detected ${BASH_VERSION}." >&2
        return 1
    fi

    for command_name in "${required_commands[@]}"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            missing_commands+=("$command_name")
        fi
    done

    if ((${#missing_commands[@]} > 0)); then
        echo "Missing required command(s): ${missing_commands[*]}" >&2
        return 1
    fi

    aarp_print_configuration
    echo "Preflight completed. Provider authentication will be verified by OpenClaude on first use."
}