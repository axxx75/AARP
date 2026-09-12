#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

DEFAULTS="$(
    env \
        -u CLAUDE_CODE_OPENAI_CONTEXT_WINDOWS \
        -u CLAUDE_CODE_OPENAI_MAX_OUTPUT_TOKENS \
        bash -c '
            source "$1/scripts/runtime_config.sh"
            printf "%s\n---\n%s\n" \
                "$CLAUDE_CODE_OPENAI_CONTEXT_WINDOWS" \
                "$CLAUDE_CODE_OPENAI_MAX_OUTPUT_TOKENS"
        ' _ "$PROJECT_DIR"
)"
[[ "$DEFAULTS" == *'"google/gemini-2.5-flash": 1048576'* ]] ||
    fail "default context-window map is incomplete"
[[ "$DEFAULTS" == *'"qwen/qwen-2.5-coder-32b-instruct:free": 8192'* ]] ||
    fail "default output-token map is incomplete"

CUSTOM_CONTEXT='{"custom/context":123}'
CUSTOM_OUTPUT='{"custom/output":456}'
OVERRIDES="$(
    CLAUDE_CODE_OPENAI_CONTEXT_WINDOWS="$CUSTOM_CONTEXT" \
    CLAUDE_CODE_OPENAI_MAX_OUTPUT_TOKENS="$CUSTOM_OUTPUT" \
        bash -c '
            source "$1/scripts/runtime_config.sh"
            printf "%s\n%s\n" \
                "$CLAUDE_CODE_OPENAI_CONTEXT_WINDOWS" \
                "$CLAUDE_CODE_OPENAI_MAX_OUTPUT_TOKENS"
        ' _ "$PROJECT_DIR"
)"
[[ "$OVERRIDES" == "${CUSTOM_CONTEXT}"$'\n'"${CUSTOM_OUTPUT}" ]] ||
    fail "caller JSON overrides were modified"

FAKE_BIN="$(mktemp -d)"
trap 'rm -rf "$FAKE_BIN"' EXIT
cat > "${FAKE_BIN}/openclaude" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${FAKE_BIN}/openclaude"

CHECK_OUTPUT="$(
    PATH="${FAKE_BIN}:${PATH}" \
        bash "${PROJECT_DIR}/scripts/orchestrator.sh" --check
)"
[[ "$CHECK_OUTPUT" == *"Preflight completed."* ]] ||
    fail "orchestrator --check did not complete"

echo "runtime_config_test: PASS"