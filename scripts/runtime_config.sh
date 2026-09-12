#!/usr/bin/env bash

# Shared runtime defaults. Every value remains overridable by the caller.
export OPENCLAUDE_PROVIDER="${OPENCLAUDE_PROVIDER:-openrouter}"

export MODEL_GENERAL="${MODEL_GENERAL:-google/gemini-2.5-flash}"
export MODEL_REASONING="${MODEL_REASONING:-google/gemini-2.5-flash}"
export MODEL_DOCUMENTATION="${MODEL_DOCUMENTATION:-google/gemini-2.5-flash}"
export MODEL_REGRESSION="${MODEL_REGRESSION:-cohere/north-mini-code:free}"

if [[ -z "${CLAUDE_CODE_OPENAI_CONTEXT_WINDOWS:-}" ]]; then
    export CLAUDE_CODE_OPENAI_CONTEXT_WINDOWS='{
  "thinkingmachines/inkling:free": 262144,
  "cohere/north-mini-code:free": 256000,
  "google/gemma-2-9b-it:free": 131072,
  "qwen/qwen-2.5-coder-32b-instruct:free": 131072,
  "anthropic/claude-3.5-sonnet": 200000,
  "deepseek/deepseek-r1": 163840,
  "google/gemini-2.5-flash": 1048576
}'
else
    export CLAUDE_CODE_OPENAI_CONTEXT_WINDOWS
fi

if [[ -z "${CLAUDE_CODE_OPENAI_MAX_OUTPUT_TOKENS:-}" ]]; then
    export CLAUDE_CODE_OPENAI_MAX_OUTPUT_TOKENS='{
  "thinkingmachines/inkling:free": 8192,
  "cohere/north-mini-code:free": 4096,
  "google/gemma-2-9b-it:free": 8192,
  "qwen/qwen-2.5-coder-32b-instruct:free": 8192,
  "anthropic/claude-3.5-sonnet": 8192,
  "deepseek/deepseek-r1": 8192,
  "google/gemini-2.5-flash": 8192
}'
else
    export CLAUDE_CODE_OPENAI_MAX_OUTPUT_TOKENS
fi

export OPENAI_TEMPERATURE="${OPENAI_TEMPERATURE:-0.2}"
export OPENROUTER_TIMEOUT="${OPENROUTER_TIMEOUT:-300}"
export OPENROUTER_MAX_RETRIES="${OPENROUTER_MAX_RETRIES:-3}"
export NODE_NO_WARNINGS="${NODE_NO_WARNINGS:-1}"
export DISABLE_TELEMETRY="${DISABLE_TELEMETRY:-1}"
export CLAUDE_CODE_DISABLE_BANNER="${CLAUDE_CODE_DISABLE_BANNER:-1}"