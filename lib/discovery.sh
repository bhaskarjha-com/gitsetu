#!/usr/bin/env bash
# lib/discovery.sh — Auto-discovery engine for GitSetu
#
# Scans the system for existing Git configurations, SSH keys,
# and common workspace directories to pre-populate the setup blueprint.

# ------------------------------------------------------------------------------
# discover_global_git_identity
#
# Returns global name and email from ~/.gitconfig if present.
# Variables set: DISCOVERED_GLOBAL_NAME, DISCOVERED_GLOBAL_EMAIL
# ------------------------------------------------------------------------------
discover_global_git_identity() {
    DISCOVERED_GLOBAL_NAME=""
    DISCOVERED_GLOBAL_EMAIL=""

    # 1. Try to read from git config
    if command -v git >/dev/null 2>&1; then
        DISCOVERED_GLOBAL_NAME=$(git config --global user.name 2>/dev/null || true)
        DISCOVERED_GLOBAL_EMAIL=$(git config --global user.email 2>/dev/null || true)
    fi

    # 2. If name/email are empty, check if global.gitconfig exists (GitSetu fallback)
    if [[ -z "$DISCOVERED_GLOBAL_NAME" ]] && [[ -f "$HOME/.config/gitsetu/profiles/global.gitconfig" ]]; then
        DISCOVERED_GLOBAL_NAME=$(git config --file "$HOME/.config/gitsetu/profiles/global.gitconfig" user.name 2>/dev/null || true)
    fi
    if [[ -z "$DISCOVERED_GLOBAL_EMAIL" ]] && [[ -f "$HOME/.config/gitsetu/profiles/global.gitconfig" ]]; then
        DISCOVERED_GLOBAL_EMAIL=$(git config --file "$HOME/.config/gitsetu/profiles/global.gitconfig" user.email 2>/dev/null || true)
    fi

    # 3. If email is STILL empty, try to extract it from SSH public keys
    if [[ -z "$DISCOVERED_GLOBAL_EMAIL" ]]; then
        local pub_key
        for pub_key in "$HOME/.ssh/id_ed25519_global.pub" "$HOME/.ssh/id_rsa_global.pub" "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
            if [[ -f "$pub_key" ]]; then
                local extracted
                extracted=$(awk '{print $3}' "$pub_key" | grep "@" || true)
                if [[ -n "$extracted" ]]; then
                    DISCOVERED_GLOBAL_EMAIL="$extracted"
                    break
                fi
            fi
        done
    fi
}

# ------------------------------------------------------------------------------
# discover_ssh_keys
#
# Scans ~/.ssh/ for ed25519 or rsa keys and returns the best match for a label.
#
# Usage: key_path=$(discover_ssh_key_for_label "work")
# Returns: path or empty string
# ------------------------------------------------------------------------------
discover_ssh_key_for_label() {
    local label="$1"
    local ssh_dir="$HOME/.ssh"
    
    if [[ ! -d "$ssh_dir" ]]; then
        echo ""
        return
    fi

    # Patterns to look for, in order of preference
    local patterns=(
        "id_ed25519_sk_${label}"
        "id_ed25519_${label}"
        "id_rsa_${label}"
    )

    local p
    for p in "${patterns[@]}"; do
        if [[ -f "$ssh_dir/$p" ]]; then
            echo "$ssh_dir/$p"
            return
        fi
    done

    echo ""
}

# ------------------------------------------------------------------------------
# discover_workspace_dir
#
# Checks if common workspace directories exist for a label.
# e.g. "work" -> ~/work, ~/dev/work
#
# Usage: dir=$(discover_workspace_dir "work")
# Returns: path or empty string
# ------------------------------------------------------------------------------
discover_workspace_dir() {
    local label="$1"
    
    # Don't try to guess for generic global labels
    if [[ "$label" == "global" ]] || [[ "$label" == "default" ]]; then
        echo ""
        return
    fi

    # 1. Parse existing ~/.gitconfig for includeIf paths containing the label
    if [[ -f "$HOME/.gitconfig" ]]; then
        local extracted
        extracted=$(grep -i "includeIf.*gitdir:.*${label}" "$HOME/.gitconfig" | head -n1 | sed 's/.*gitdir:\([^"]*\)".*/\1/' || true)
        if [[ -n "$extracted" ]]; then
            extracted="${extracted/#\~/$HOME}"
            extracted="${extracted%/}"
            if [[ -d "$extracted" ]]; then
                echo "$extracted"
                return
            fi
        fi
        
        # Or look for exact match if label is something else
        extracted=$(grep -i "includeIf.*gitdir" "$HOME/.gitconfig" | grep -i "$label" | head -n1 | sed 's/.*gitdir:\([^"]*\)".*/\1/' || true)
        if [[ -n "$extracted" ]]; then
            extracted="${extracted/#\~/$HOME}"
            extracted="${extracted%/}"
            if [[ -d "$extracted" ]]; then
                echo "$extracted"
                return
            fi
        fi
    fi

    # 2. Hardcoded fallback paths
    local potential_dirs=(
        "$HOME/$label"
        "$HOME/dev/$label"
        "$HOME/Development/$label"
        "$HOME/workspace/$label"
        "$HOME/projects/$label"
    )

    local p
    for p in "${potential_dirs[@]}"; do
        if [[ -d "$p" ]]; then
            echo "$p"
            return
        fi
    done

    echo ""
}

# ------------------------------------------------------------------------------
# generate_initial_blueprint
#
# Initializes PROFILE_* arrays with discovered defaults if profiles.conf is empty.
# ------------------------------------------------------------------------------
generate_initial_blueprint() {
    # If we already have profiles (from load_profiles), do nothing
    if [[ "$PROFILE_COUNT" -gt 0 ]]; then
        return 0
    fi

    discover_global_git_identity

    # Initialize Global Profile (Index 0)
    # shellcheck disable=SC2034
    PROFILE_LABELS[0]="global"
    # shellcheck disable=SC2034
    PROFILE_NAMES[0]="${DISCOVERED_GLOBAL_NAME:-}"
    # shellcheck disable=SC2034
    PROFILE_EMAILS[0]="${DISCOVERED_GLOBAL_EMAIL:-}"
    # shellcheck disable=SC2034
    PROFILE_DIRS[0]=""
    # shellcheck disable=SC2034
    PROFILE_PROVIDERS[0]="github.com"
    # shellcheck disable=SC2034
    PROFILE_SIGNS[0]="0"
    
    local global_key
    global_key=$(discover_ssh_key_for_label "global")
    # shellcheck disable=SC2034
    PROFILE_KEYS[0]="${global_key:-$HOME/.ssh/id_ed25519_global}"
    # shellcheck disable=SC2034
    PROFILE_USERS[0]=""
    # shellcheck disable=SC2034
    PROFILE_PATS[0]=""
    
    PROFILE_COUNT=1

    # Try to discover a 'work' profile if the directory exists
    local work_dir
    work_dir=$(discover_workspace_dir "work")
    if [[ -n "$work_dir" ]]; then
        # shellcheck disable=SC2034
        PROFILE_LABELS[1]="work"
        # shellcheck disable=SC2034
        PROFILE_NAMES[1]="${DISCOVERED_GLOBAL_NAME:-}"
        # shellcheck disable=SC2034
        PROFILE_EMAILS[1]="" # User must fill this in
        # shellcheck disable=SC2034
        PROFILE_DIRS[1]="$work_dir"
        # shellcheck disable=SC2034
        PROFILE_PROVIDERS[1]="github.com"
        # shellcheck disable=SC2034
        PROFILE_SIGNS[1]="0"
        
        local work_key
        work_key=$(discover_ssh_key_for_label "work")
        # shellcheck disable=SC2034
        PROFILE_KEYS[1]="${work_key:-$HOME/.ssh/id_ed25519_work}"
        # shellcheck disable=SC2034
        PROFILE_USERS[1]=""
        # shellcheck disable=SC2034
        PROFILE_PATS[1]=""
        
        PROFILE_COUNT=2
    fi
}
