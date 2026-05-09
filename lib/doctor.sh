#!/usr/bin/env bash
# lib/doctor.sh — GitSetu Diagnostics Module
#
# Analyzes the current environment to help users troubleshoot Git identity issues.

# ------------------------------------------------------------------------------
# run_doctor — Execute system diagnostics
# ------------------------------------------------------------------------------
run_doctor() {
    print_section "GitSetu Diagnostics (Doctor)"

    # 1. Determine active profile based on PWD
    local current_dir="$PWD"
    local active_profile="global"
    local active_dir="[Global Fallback]"
    
    local i
    # Iterate backwards so more specific (later) profiles win
    for (( i=PROFILE_COUNT-1; i>=1; i-- )); do
        local dir="${PROFILE_DIRS[$i]}"
        if [[ -n "$dir" ]] && [[ "$current_dir" == "$dir"* ]]; then
            active_profile="${PROFILE_LABELS[$i]}"
            active_dir="$dir"
            break
        fi
    done

    printf "  %bDirectory Match:%b\n" "$BOLD" "$RESET"
    printf "    Current PWD: %s\n" "$current_dir"
    printf "    Active Profile: %b%s%b\n" "$GREEN" "$active_profile" "$RESET"
    if [[ "$active_profile" != "global" ]]; then
        printf "    Matched Rule: %s\n" "$active_dir"
    else
        printf "    Matched Rule: No profile directory matched, falling back to global.\n"
    fi
    printf "\n"

    # 2. Check Git resolution
    printf "  %bGit Identity Resolution:%b\n" "$BOLD" "$RESET"
    
    local resolved_name
    local resolved_email
    local resolved_key

    if command -v git >/dev/null 2>&1; then
        resolved_name=$(git config user.name 2>/dev/null || echo "(Not Configured)")
        resolved_email=$(git config user.email 2>/dev/null || echo "(Not Configured)")
        resolved_key=$(git config core.sshCommand 2>/dev/null | awk -F '-i ' '{print $2}' | awk '{print $1}' || echo "(Not Configured)")
        
        printf "    Resolved Name: %s\n" "$resolved_name"
        printf "    Resolved Email: %s\n" "$resolved_email"
        printf "    Resolved Key: %s\n" "$resolved_key"
    else
        printf "    %bGit is not installed or not in PATH!%b\n" "$RED" "$RESET"
    fi
    printf "\n"

    # 3. Check SSH Agent Status
    printf "  %bSSH Agent Status:%b\n" "$BOLD" "$RESET"
    
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
        printf "    %bWARNING: SSH_AUTH_SOCK is not set. The ssh-agent is not running!%b\n" "$YELLOW" "$RESET"
        printf "    Run: eval \"\$(ssh-agent -s)\"\n"
    else
        printf "    Status: Running (Socket: %s)\n" "$SSH_AUTH_SOCK"
        
        local loaded_keys
        loaded_keys=$(ssh-add -l 2>/dev/null || true)
        
        if [[ "$loaded_keys" == *"The agent has no identities"* ]] || [[ -z "$loaded_keys" ]]; then
            printf "    Loaded Keys: %bNone!%b\n" "$YELLOW" "$RESET"
            printf "    Run: ssh-add ~/.ssh/id_ed25519_%s\n" "$active_profile"
        else
            printf "    Loaded Keys:\n"
            echo "$loaded_keys" | while read -r line; do
                printf "      - %s\n" "$line"
            done
        fi
    fi
    
    printf "\n"
    
    # 4. Check Config Integrity
    printf "  %bGitSetu Integrity:%b\n" "$BOLD" "$RESET"
    if [[ ! -f "$GITSETU_PROFILES_CONF" ]]; then
        printf "    %bERROR: Registry missing at %s%b\n" "$RED" "$GITSETU_PROFILES_CONF" "$RESET"
    else
        printf "    Registry: OK\n"
    fi
    
    if grep -qF "${GITSETU_MANAGED_START}" "$HOME/.gitconfig" 2>/dev/null; then
        printf "    ~/.gitconfig: OK (Managed blocks present)\n"
    else
        printf "    ~/.gitconfig: %bWARNING (Managed blocks missing)%b\n" "$YELLOW" "$RESET"
    fi

    if grep -qF "${GITSETU_MANAGED_START}" "$HOME/.ssh/config" 2>/dev/null; then
        printf "    ~/.ssh/config: OK (Managed blocks present)\n"
    else
        printf "    ~/.ssh/config: %bWARNING (Managed blocks missing)%b\n" "$YELLOW" "$RESET"
    fi
    
    echo ""
}
