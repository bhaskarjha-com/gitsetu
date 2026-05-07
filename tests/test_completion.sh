#!/usr/bin/env bash
# tests/test_completion.sh — Tests for completion.sh
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
setup_test_home

# Mock the bash complete function
complete() {
    true
}
export -f complete

test_completion_sources() {
    local script
    script="$(dirname "${BASH_SOURCE[0]}")/../lib/completion.sh"
    # Sourcing it should not fail
    # shellcheck disable=SC1090
    source "$script"
    # Function _gitsetu should be defined
    if ! declare -F _gitsetu >/dev/null; then
        echo "_gitsetu function not found after sourcing"
        return 1
    fi
    return 0
}

printf '\n%btest_completion.sh%b\n' "$T_BOLD" "$T_RESET"
run_test "completion script sources cleanly" test_completion_sources
print_results "Completion tests"
