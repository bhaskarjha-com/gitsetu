#!/usr/bin/env bash
# tests/test_credential.sh — Tests for the Git credential helper broker
#
# Uses a portable POSIX timeout watchdog (macOS lacks GNU `timeout`).
# If a subprocess hangs, the watchdog kills it after 15s and the test
# fails cleanly instead of hanging CI forever.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
setup_test_home

GITSETU_EXE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/gitsetu"
GITSETU_EXE="${GITSETU_EXE%$'\r'}"

# Force file-fallback path for credential storage in tests.
# On macOS CI, `security add-internet-password` hangs because there is no
# unlocked user keychain in headless environments.
#
# We use a marker file ($HOME/.config/gitsetu/.test_os) because macOS
# bash 3.2 does NOT propagate environment variables through pipelines
# inside background subshells (confirmed empirically: export, POSIX
# command prefix, and subshell export all fail).
#
# detect_os() checks for this file and sets GITSETU_OS to its contents,
# bypassing native OS detection and preventing keychain calls.
mkdir -p "$HOME/.config/gitsetu"
printf 'test' > "$HOME/.config/gitsetu/.test_os"

# ------------------------------------------------------------------------------
# Helper: run gitsetu credential with a portable POSIX timeout watchdog.
#
# Usage: _run_credential <timeout_secs> <stdin_data> [args...]
# Returns: exit code of the gitsetu command, or 137 on timeout (SIGKILL)
# Stdout: whatever gitsetu prints to stdout (for credential get)
# ------------------------------------------------------------------------------
_run_credential() {
    local timeout_secs="$1"
    local stdin_data="$2"
    shift 2

    local stdout_log="$HOME/.credential_stdout_$$.log"

    # Run in a background subshell (portable — no GNU timeout needed).
    # OS override is via marker file, not env var (bash 3.2 limitation).
    (printf "%b" "$stdin_data" | bash "$GITSETU_EXE" "$@" \
        >"$stdout_log" 2>/dev/null) &
    local cmd_pid=$!

    # Watchdog: kill the command after timeout_secs
    (sleep "$timeout_secs" && kill -9 "$cmd_pid" 2>/dev/null) &
    local watchdog_pid=$!

    # Wait for the command to finish
    local rc=0
    wait "$cmd_pid" 2>/dev/null || rc=$?

    # Kill the watchdog (command finished before timeout)
    kill "$watchdog_pid" 2>/dev/null || true
    wait "$watchdog_pid" 2>/dev/null || true

    if [[ $rc -ne 0 ]]; then
        rm -f "$stdout_log"
        return "$rc"
    fi

    # Print stdout (needed for credential get)
    cat "$stdout_log" 2>/dev/null
    rm -f "$stdout_log"
    return 0
}

test_credential_broker() {
    mkdir -p "$HOME/.config/gitsetu"

    # Create a dummy registry
    cat > "$HOME/.config/gitsetu/profiles.conf" <<EOF
global::/invalid:github.com:0:~/.ssh/id_ed25519_global:global_user
work::$HOME/work:github.com:0:~/.ssh/id_ed25519_work:work_user
EOF

    mkdir -p "$HOME/work"
    cd "$HOME/work" || return 1

    # 1. Test storing credentials (simulating Git's stdin)
    local store_input="protocol=https\nhost=github.com\nusername=work_user\npassword=secret_pat_123\n\n"
    _run_credential 15 "$store_input" credential store || {
        printf '    FAIL: credential store hung or failed\n'
        return 1
    }

    # Verify it hit the fallback file
    assert_equals 0 $? "credential store exits cleanly" || return 1

    # 2. Test getting credentials
    local get_input="protocol=https\nhost=github.com\n\n"
    local get_output
    get_output=$(_run_credential 15 "$get_input" credential get) || {
        printf '    FAIL: credential get hung or failed\n'
        return 1
    }

    # It should output username=... and password=...
    if [[ "$get_output" != *"username=work_user"* ]] || [[ "$get_output" != *"password=secret_pat_123"* ]]; then
        echo "Failed to retrieve correct credentials. Output: $get_output"
        return 1
    fi

    # 3. Test erase
    _run_credential 15 "$store_input" credential erase || {
        printf '    FAIL: credential erase hung or failed\n'
        return 1
    }

    local get_output_after
    get_output_after=$(_run_credential 15 "$get_input" credential get || true)
    if [[ -n "$get_output_after" ]]; then
        echo "Credentials were not erased properly. Output: $get_output_after"
        return 1
    fi

    return 0
}

test_credential_ignores_ssh() {
    mkdir -p "$HOME/.config/gitsetu"
    cat > "$HOME/.config/gitsetu/profiles.conf" <<EOF
work::$HOME/work:github.com:0:~/.ssh/id_ed25519_work:work_user
EOF
    mkdir -p "$HOME/work"
    cd "$HOME/work" || return 1

    # SSH protocol should be ignored
    local get_input="protocol=ssh\nhost=github.com\n\n"
    local get_output
    get_output=$(_run_credential 15 "$get_input" credential get || true)

    assert_equals "" "$get_output" "ssh protocol is ignored" || return 1
}

test_credential_outside_profile() {
    mkdir -p "$HOME/.config/gitsetu"
    cat > "$HOME/.config/gitsetu/profiles.conf" <<EOF
work::$HOME/work:github.com:0:~/.ssh/id_ed25519_work:work_user
EOF
    mkdir -p "$HOME/personal"
    cd "$HOME/personal" || return 1

    local get_input="protocol=https\nhost=github.com\n\n"
    local get_output
    get_output=$(_run_credential 15 "$get_input" credential get || true)

    assert_equals "" "$get_output" "empty output when outside profile directory" || return 1
}

printf '\n%btest_credential.sh%b\n' "$T_BOLD" "$T_RESET"
run_test "Credential broker roundtrip (store/get/erase)" test_credential_broker
run_test "Credential broker ignores ssh protocol" test_credential_ignores_ssh
run_test "Credential broker ignores non-profile directories" test_credential_outside_profile
print_results "Credential tests"
