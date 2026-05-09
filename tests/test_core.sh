#!/usr/bin/env bash
# tests/test_core.sh — Unit tests for lib/core.sh
#
# Tests: load_profiles(), remove_profile_at_index(), to_lower(), array_contains()
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
setup_test_home

source_gitsetu_libs

# ==============================================================================
# to_lower
# ==============================================================================
test_to_lower_basic() {
    local result
    result=$(to_lower "FooBar")
    assert_equals "foobar" "$result" "converts mixed case to lowercase"
}

test_to_lower_already_lower() {
    local result
    result=$(to_lower "hello")
    assert_equals "hello" "$result" "no-op on lowercase"
}

test_to_lower_all_upper() {
    local result
    result=$(to_lower "HELLO")
    assert_equals "hello" "$result" "converts all uppercase"
}

test_to_lower_empty() {
    local result
    result=$(to_lower "")
    assert_equals "" "$result" "handles empty string"
}

# ==============================================================================
# array_contains
# ==============================================================================
test_array_contains_found() {
    local arr=("alpha" "beta" "gamma")
    array_contains "beta" "${arr[@]}"
}

test_array_contains_not_found() {
    local arr=("alpha" "beta" "gamma")
    ! array_contains "delta" "${arr[@]}"
}

test_array_contains_single() {
    local arr=("only")
    array_contains "only" "${arr[@]}"
}

test_array_contains_empty_needle() {
    local arr=("alpha" "" "gamma")
    array_contains "" "${arr[@]}"
}

# ==============================================================================
# load_profiles — normal case
# ==============================================================================
test_load_profiles_basic() {
    setup_test_home
    source_gitsetu_libs

    mkdir -p "$HOME/.config/gitsetu/profiles"

    # Create a profile gitconfig
    cat > "$HOME/.config/gitsetu/profiles/work.gitconfig" <<EOF
[user]
    name = Work User
    email = work@corp.com
[core]
    sshCommand = ssh -i $HOME/.ssh/id_ed25519_work
EOF

    # Create profiles.conf with empty email column (canonical format)
    cat > "$HOME/.config/gitsetu/profiles.conf" <<EOF
work::$HOME/work:github.com:0:$HOME/.ssh/id_ed25519_work:ghuser
EOF

    load_profiles

    assert_equals 1 "$PROFILE_COUNT" "loaded 1 profile" &&
    assert_equals "work" "${PROFILE_LABELS[0]}" "label is work" &&
    assert_equals "Work User" "${PROFILE_NAMES[0]}" "name loaded from gitconfig" &&
    assert_equals "work@corp.com" "${PROFILE_EMAILS[0]}" "email loaded from gitconfig" &&
    assert_equals "$HOME/work" "${PROFILE_DIRS[0]}" "dir parsed correctly" &&
    assert_equals "github.com" "${PROFILE_PROVIDERS[0]}" "provider parsed" &&
    assert_equals "0" "${PROFILE_SIGNS[0]}" "sign_commits parsed" &&
    assert_equals "$HOME/.ssh/id_ed25519_work" "${PROFILE_KEYS[0]}" "key_path parsed" &&
    assert_equals "ghuser" "${PROFILE_USERS[0]}" "provider_user parsed"
}

# ==============================================================================
# load_profiles — empty file
# ==============================================================================
test_load_profiles_empty_file() {
    setup_test_home
    source_gitsetu_libs

    mkdir -p "$HOME/.config/gitsetu"
    touch "$HOME/.config/gitsetu/profiles.conf"

    load_profiles

    assert_equals 0 "$PROFILE_COUNT" "empty file yields 0 profiles"
}

# ==============================================================================
# load_profiles — comments only
# ==============================================================================
test_load_profiles_comments_only() {
    setup_test_home
    source_gitsetu_libs

    mkdir -p "$HOME/.config/gitsetu"
    cat > "$HOME/.config/gitsetu/profiles.conf" <<EOF
# gitsetu profile registry
# Format: label:email:directory:provider:sign_commits:key_path:provider_user
EOF

    load_profiles

    assert_equals 0 "$PROFILE_COUNT" "comment-only file yields 0 profiles"
}

# ==============================================================================
# load_profiles — missing profiles.conf
# ==============================================================================
test_load_profiles_no_file() {
    setup_test_home
    source_gitsetu_libs

    # Don't create profiles.conf
    load_profiles

    assert_equals 0 "$PROFILE_COUNT" "missing file yields 0 profiles"
}

# ==============================================================================
# load_profiles — multiple profiles
# ==============================================================================
test_load_profiles_multiple() {
    setup_test_home
    source_gitsetu_libs

    mkdir -p "$HOME/.config/gitsetu/profiles"

    cat > "$HOME/.config/gitsetu/profiles/global.gitconfig" <<EOF
[user]
    name = Global
    email = global@test.com
EOF
    cat > "$HOME/.config/gitsetu/profiles/work.gitconfig" <<EOF
[user]
    name = Worker
    email = worker@corp.com
EOF

    cat > "$HOME/.config/gitsetu/profiles.conf" <<EOF
# comment
global::::github.com:0:$HOME/.ssh/id_ed25519_global:
work::$HOME/work:github.com:1:$HOME/.ssh/id_ed25519_work:myuser
EOF

    load_profiles

    assert_equals 2 "$PROFILE_COUNT" "loaded 2 profiles" &&
    assert_equals "global" "${PROFILE_LABELS[0]}" "first label" &&
    assert_equals "work" "${PROFILE_LABELS[1]}" "second label" &&
    assert_equals "1" "${PROFILE_SIGNS[1]}" "sign_commits for work" &&
    assert_equals "myuser" "${PROFILE_USERS[1]}" "provider_user for work"
}

# ==============================================================================
# remove_profile_at_index — basic removal
# ==============================================================================
test_remove_profile_basic() {
    setup_test_home
    source_gitsetu_libs

    PROFILE_COUNT=3
    PROFILE_LABELS=("global" "work" "oss")
    PROFILE_NAMES=("G" "W" "O")
    PROFILE_EMAILS=("g@t.com" "w@t.com" "o@t.com")
    PROFILE_DIRS=("" "/work" "/oss")
    PROFILE_PROVIDERS=("github.com" "github.com" "gitlab.com")
    PROFILE_SIGNS=("0" "1" "0")
    PROFILE_KEYS=("k1" "k2" "k3")
    PROFILE_USERS=("u1" "u2" "u3")
    PROFILE_PATS=("" "" "")

    remove_profile_at_index 1

    assert_equals 2 "$PROFILE_COUNT" "count decremented" &&
    assert_equals "global" "${PROFILE_LABELS[0]}" "global preserved" &&
    assert_equals "oss" "${PROFILE_LABELS[1]}" "oss shifted to index 1" &&
    assert_equals "o@t.com" "${PROFILE_EMAILS[1]}" "oss email shifted" &&
    assert_equals "gitlab.com" "${PROFILE_PROVIDERS[1]}" "oss provider shifted" &&
    assert_equals "u3" "${PROFILE_USERS[1]}" "oss user shifted"
}

# ==============================================================================
# remove_profile_at_index — remove last element (boundary)
# ==============================================================================
test_remove_profile_last() {
    setup_test_home
    source_gitsetu_libs

    PROFILE_COUNT=2
    PROFILE_LABELS=("global" "work")
    PROFILE_NAMES=("G" "W")
    PROFILE_EMAILS=("g@t.com" "w@t.com")
    PROFILE_DIRS=("" "/work")
    PROFILE_PROVIDERS=("github.com" "github.com")
    PROFILE_SIGNS=("0" "0")
    PROFILE_KEYS=("k1" "k2")
    PROFILE_USERS=("" "")
    PROFILE_PATS=("" "")

    remove_profile_at_index 1

    assert_equals 1 "$PROFILE_COUNT" "count is 1" &&
    assert_equals "global" "${PROFILE_LABELS[0]}" "global preserved"
}

# ==============================================================================
# remove_profile_at_index — remove to empty
# ==============================================================================
test_remove_profile_to_empty() {
    setup_test_home
    source_gitsetu_libs

    PROFILE_COUNT=1
    PROFILE_LABELS=("only")
    PROFILE_NAMES=("O")
    PROFILE_EMAILS=("o@t.com")
    PROFILE_DIRS=("")
    PROFILE_PROVIDERS=("github.com")
    PROFILE_SIGNS=("0")
    PROFILE_KEYS=("k1")
    PROFILE_USERS=("")
    PROFILE_PATS=("")

    remove_profile_at_index 0

    assert_equals 0 "$PROFILE_COUNT" "count is 0 after removing last"
}

# ==============================================================================
# remove_profile_at_index — out of bounds
# ==============================================================================
test_remove_profile_out_of_bounds() {
    setup_test_home
    source_gitsetu_libs

    PROFILE_COUNT=1
    PROFILE_LABELS=("only")
    PROFILE_NAMES=("O")
    PROFILE_EMAILS=("o@t.com")
    PROFILE_DIRS=("")
    PROFILE_PROVIDERS=("github.com")
    PROFILE_SIGNS=("0")
    PROFILE_KEYS=("k1")
    PROFILE_USERS=("")
    PROFILE_PATS=("")

    local result=0
    remove_profile_at_index 5 || result=$?

    assert_equals 1 "$result" "returns 1 for out of bounds" &&
    assert_equals 1 "$PROFILE_COUNT" "count unchanged"
}

# ==============================================================================
# Top-level array initialization (all 9 arrays declared)
# ==============================================================================
test_top_level_array_init() {
    # After sourcing core.sh, all 9 arrays should exist (even if empty)
    # Under set -u, accessing an uninitialized variable would crash
    local users_val="${PROFILE_USERS-UNSET}"
    local pats_val="${PROFILE_PATS-UNSET}"
    local labels_val="${PROFILE_LABELS-UNSET}"

    # They should NOT be "UNSET"
    if [[ "$users_val" == "UNSET" ]]; then
        printf '    FAIL: PROFILE_USERS not initialized at module scope\n'
        return 1
    fi
    if [[ "$pats_val" == "UNSET" ]]; then
        printf '    FAIL: PROFILE_PATS not initialized at module scope\n'
        return 1
    fi
    return 0
}

# ==============================================================================
# Run
# ==============================================================================
printf '\n%btest_core.sh%b\n' "$T_BOLD" "$T_RESET"
run_test "to_lower: mixed case" test_to_lower_basic
run_test "to_lower: already lowercase" test_to_lower_already_lower
run_test "to_lower: all uppercase" test_to_lower_all_upper
run_test "to_lower: empty string" test_to_lower_empty
run_test "array_contains: found" test_array_contains_found
run_test "array_contains: not found" test_array_contains_not_found
run_test "array_contains: single element" test_array_contains_single
run_test "array_contains: empty needle" test_array_contains_empty_needle
run_test "load_profiles: basic 7-field parse" test_load_profiles_basic
run_test "load_profiles: empty file" test_load_profiles_empty_file
run_test "load_profiles: comments only" test_load_profiles_comments_only
run_test "load_profiles: missing file" test_load_profiles_no_file
run_test "load_profiles: multiple profiles" test_load_profiles_multiple
run_test "remove_profile: basic removal" test_remove_profile_basic
run_test "remove_profile: remove last element" test_remove_profile_last
run_test "remove_profile: remove to empty" test_remove_profile_to_empty
run_test "remove_profile: out of bounds" test_remove_profile_out_of_bounds
run_test "top-level: all 9 arrays initialized" test_top_level_array_init
print_results "Core tests"
