#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TESTS=(
    "tests/runtime_config_test.sh"
    "tests/documentation_helpers_test.sh"
    "tests/documentation_orchestrator_test.sh"
    "tests/report_validation_test.sh"
    "tests/roadmap_helpers_test.sh"
)

for test_file in "${TESTS[@]}"; do
    echo
    echo "==> ${test_file}"
    bash "${PROJECT_DIR}/${test_file}"
done

echo
echo "All AARP test fixtures passed."