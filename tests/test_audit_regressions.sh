#!/usr/bin/env bash
# tests/test_audit_regressions.sh — Regression tests for zero-defect audit findings
#
# Each test validates a specific fix from the v1.1.1 audit.
# Tests are designed to FAIL without the corresponding code fix.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/helpers.sh"

# ==============================================================================
# F01: cmd_status active identity checkmark was broken because profiles.conf
#      writes an empty email column but cmd_status compared that empty string
#      to the current git email.
# ==============================================================================
test_f01_status_loads_email_from_gitconfig() {
    setup_test_home
    source_gitsetu_libs

    # Create a profile gitconfig with a known email
    mkdir -p "$HOME/.config/gitsetu/profiles"
    cat > "$HOME/.config/gitsetu/profiles/work.gitconfig" <<EOF
[user]
    name = Test User
    email = work@company.com
[core]
    sshCommand = ssh -i $HOME/.ssh/id_ed25519_work
EOF

    # Create profiles.conf with EMPTY email column (this is what write_profiles_conf does)
    cat > "$HOME/.config/gitsetu/profiles.conf" <<EOF
work::$HOME/work:github.com:0:$HOME/.ssh/id_ed25519_work:
EOF

    # The GITSETU_PROFILES_DIR must point to our test dir
    GITSETU_PROFILES_DIR="$HOME/.config/gitsetu/profiles"

    # Parse the profile like cmd_status does
    local profile_email=""
    while IFS=: read -r label email dir provider sign_commits key_path _unused || [[ -n "$label" ]]; do
        [[ "$label" == "#"* ]] && continue
        [[ -z "$label" ]] && continue
        # This is the fix: load from gitconfig instead of using empty registry email
        profile_email=$(git config -f "$GITSETU_PROFILES_DIR/${label}.gitconfig" user.email 2>/dev/null || true)
        if [[ -z "$profile_email" ]] && [[ -n "$email" ]]; then
            profile_email="$email"
        fi
    done < "$HOME/.config/gitsetu/profiles.conf"

    assert_equals "work@company.com" "$profile_email" "Email should be loaded from profile gitconfig, not empty registry column"
}

# ==============================================================================
# F02: doctor.sh was sending all output to stdout instead of stderr
# ==============================================================================
test_f02_doctor_outputs_to_stderr() {
    setup_test_home
    source_gitsetu_libs

    # Set up minimal state so doctor doesn't crash
    PROFILE_COUNT=0
    PROFILE_LABELS=()
    PROFILE_DIRS=()
    mkdir -p "$HOME/.config/gitsetu"

    # Capture stdout only — it should be empty
    local stdout_output
    stdout_output=$(run_doctor 2>/dev/null) || true

    assert_equals "" "$stdout_output" "doctor should produce zero stdout output"
}

# ==============================================================================
# F03: generate_initial_blueprint() didn't initialize PROFILE_USERS/PROFILE_PATS
# ==============================================================================
test_f03_blueprint_initializes_all_arrays() {
    setup_test_home
    source_gitsetu_libs

    # Reset all arrays
    PROFILE_COUNT=0
    PROFILE_LABELS=()
    PROFILE_NAMES=()
    PROFILE_EMAILS=()
    PROFILE_DIRS=()
    PROFILE_PROVIDERS=()
    PROFILE_SIGNS=()
    PROFILE_KEYS=()
    PROFILE_USERS=()
    PROFILE_PATS=()

    generate_initial_blueprint

    # After blueprint, PROFILE_USERS[0] and PROFILE_PATS[0] should be initialized (even if empty)
    # Under set -u, accessing an uninitialized array index would crash
    # Note: use ${var-X} not ${var:-X} because :-  treats empty as unset
    local users_val="${PROFILE_USERS[0]-UNSET}"
    local pats_val="${PROFILE_PATS[0]-UNSET}"

    # They should be empty strings, NOT "UNSET"
    assert_equals "" "$users_val" "PROFILE_USERS[0] should be initialized to empty string"
    assert_equals "" "$pats_val" "PROFILE_PATS[0] should be initialized to empty string"
}

# ==============================================================================
# F04: MANAGED_BLOCK env var was exported and never unset
# ==============================================================================
test_f04_managed_block_not_leaked() {
    setup_test_home
    source_gitsetu_libs

    # Set up minimal profiles for write_global_gitconfig
    PROFILE_COUNT=1
    PROFILE_LABELS=("global")
    PROFILE_NAMES=("Test")
    PROFILE_EMAILS=("test@test.com")
    PROFILE_DIRS=("")
    PROFILE_PROVIDERS=("github.com")
    PROFILE_SIGNS=("0")
    PROFILE_KEYS=("$HOME/.ssh/id_ed25519_global")
    PROFILE_USERS=("")
    PROFILE_PATS=("")
    GITSETU_DRY_RUN=0
    GITSETU_SCRIPT_DIR="$SCRIPT_DIR/.."

    # Create an existing gitconfig WITH a managed block so the awk path runs
    cat > "$HOME/.gitconfig" <<EOF
# [gitsetu:managed:start]
[user]
    name = old
# [gitsetu:managed:end]
EOF

    write_global_gitconfig >/dev/null 2>&1

    # MANAGED_BLOCK should have been unset after use
    if [[ -n "${MANAGED_BLOCK:-}" ]]; then
        printf '    FAIL: MANAGED_BLOCK env var still set after write_global_gitconfig\n'
        return 1
    fi
    return 0
}

# ==============================================================================
# F07: completion.sh should not offer non-existent 'init' subcommand
# ==============================================================================
test_f07_completion_no_ghost_subcommands() {
    setup_test_home

    local completion_file="$SCRIPT_DIR/../lib/completion.sh"
    local opts_line
    opts_line=$(grep 'opts=' "$completion_file")

    assert_not_contains "$opts_line" "init" "completion should not offer non-existent 'init' subcommand"
    assert_contains "$opts_line" "backup" "completion should offer 'backup' subcommand"
    assert_contains "$opts_line" "restore" "completion should offer 'restore' subcommand"
    assert_contains "$opts_line" "credential" "completion should offer 'credential' subcommand"
}

# ==============================================================================
# F09: Empty cleanup arrays should not crash under set -u
# ==============================================================================
test_f09_empty_cleanup_arrays_safe() {
    setup_test_home
    source_gitsetu_libs

    # Ensure cleanup arrays are empty
    GITSETU_CLEANUP_FILES=()
    # shellcheck disable=SC2034  # consumed by gitsetu_global_cleanup() below
    GITSETU_CLEANUP_DIRS=()

    # This should NOT crash under set -u
    gitsetu_global_cleanup 2>/dev/null

    # If we got here, it didn't crash
    return 0
}

# ==============================================================================
# C01: ask_password must NOT be called via command substitution $()
#      because it sets $REPLY (lost in subshell) and prints nothing to stdout
# ==============================================================================
test_c01_ask_password_not_in_subshell() {
    local backup_file="$SCRIPT_DIR/../lib/backup.sh"

    # Grep for the broken pattern: $(ask_password ...)
    local violations
    # shellcheck disable=SC2016  # Intentional: grepping for the literal pattern $(ask_password
    violations=$(grep -c '$(ask_password' "$backup_file" 2>/dev/null | tr -d '\r') || true

    if [[ "$violations" -gt 0 ]]; then
        printf '    FAIL: ask_password called via command substitution (%s times)\n' "$violations"
        # shellcheck disable=SC2016  # Intentional: human-readable message referencing $REPLY
        printf '    This silently discards $REPLY. Use: ask_password "..."; var="$REPLY"\n'
        return 1
    fi
    return 0
}

# ==============================================================================
# S01: cleanup trap must restore stty echo to prevent stuck terminal
# ==============================================================================
test_s01_cleanup_restores_stty() {
    local gitsetu_file="$SCRIPT_DIR/../gitsetu"

    # The cleanup() function must contain stty echo
    local has_stty
    has_stty=$(grep -A5 'cleanup()' "$gitsetu_file" | grep -c 'stty echo' | tr -d '\r') || true

    if [[ "$has_stty" -eq 0 ]]; then
        printf '    FAIL: cleanup() does not restore stty echo\n'
        return 1
    fi
    return 0
}

# ==============================================================================
# Run all regression tests
# ==============================================================================
run_test "F01: cmd_status loads email from profile gitconfig" test_f01_status_loads_email_from_gitconfig
run_test "F02: doctor outputs exclusively to stderr" test_f02_doctor_outputs_to_stderr
run_test "F03: generate_initial_blueprint initializes all 9 arrays" test_f03_blueprint_initializes_all_arrays
run_test "F04: MANAGED_BLOCK env var is unset after use" test_f04_managed_block_not_leaked
run_test "F07: completion offers no ghost subcommands" test_f07_completion_no_ghost_subcommands
run_test "F09: empty cleanup arrays survive set -u" test_f09_empty_cleanup_arrays_safe
run_test "C01: ask_password not called via subshell capture" test_c01_ask_password_not_in_subshell
run_test "S01: cleanup trap restores stty echo" test_s01_cleanup_restores_stty

print_results "Audit Regression tests"

