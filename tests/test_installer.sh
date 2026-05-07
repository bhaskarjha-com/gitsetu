#!/usr/bin/env bash
# tests/test_installer.sh — Regression tests for the distribution pipeline
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

test_installation_pipeline() {
    # 1. Create a safe sandbox home directory
    local sandbox_home
    sandbox_home=$(mktemp -d "${TMPDIR:-/tmp}/gitsetu_test_install_XXXXXX")
    
    # 2. Point to the local repo so we don't hit the network for tests
    local local_repo
    local_repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
    
    # 3. Override HOME and REPO_URL
    export HOME="$sandbox_home"
    export GITSETU_REPO_URL="$local_repo"
    
    # 3.5 Configure safe.directory for the sandbox to allow local cloning
    git config --global --add safe.directory "$local_repo"
    git config --global --add safe.directory "$local_repo/.git"
    
    # 4. Test Installation
    bash "$local_repo/install.sh" >/dev/null 2>&1
    assert_equals 0 $? "install.sh runs successfully" || return 1
    
    # Verify clone exists
    if [[ ! -d "$sandbox_home/.local/share/gitsetu" ]]; then
        echo "Failed: share directory was not created."
        rm -rf "$sandbox_home"
        return 1
    fi
    
    # Verify executable exists (checking -x instead of -L as MSYS2 may copy instead of symlink)
    if [[ ! -x "$sandbox_home/.local/bin/gitsetu" ]]; then
        echo "Failed: executable was not linked/copied to bin directory."
        rm -rf "$sandbox_home"
        return 1
    fi
    
    # 5. Verify Execution
    local version_output
    version_output=$("$sandbox_home/.local/bin/gitsetu" --version)
    if [[ "$version_output" != *"gitsetu v"* ]]; then
        echo "Failed: installed executable did not run properly. Output: $version_output"
        rm -rf "$sandbox_home"
        return 1
    fi
    
    # 6. Test Idempotent Update
    bash "$local_repo/install.sh" >/dev/null 2>&1
    assert_equals 0 $? "install.sh updates idempotently" || return 1
    
    # 7. Test Uninstallation
    # Accept the 'Are you sure?' prompt with 'y'
    echo "y" | bash "$local_repo/uninstall.sh" >/dev/null 2>&1
    assert_equals 0 $? "uninstall.sh runs successfully" || return 1
    
    # Verify removal
    if [[ -d "$sandbox_home/.local/share/gitsetu" ]]; then
        echo "Failed: share directory was not removed by uninstall.sh."
        rm -rf "$sandbox_home"
        return 1
    fi
    
    if [[ -e "$sandbox_home/.local/bin/gitsetu" ]]; then
        echo "Failed: symlink was not removed by uninstall.sh."
        rm -rf "$sandbox_home"
        return 1
    fi
    
    rm -rf "$sandbox_home"
    return 0
}

printf '\n%btest_installer.sh%b\n' "$T_BOLD" "$T_RESET"
run_test "Full Installation/Uninstallation Pipeline" test_installation_pipeline
print_results "Installer pipeline tests"
