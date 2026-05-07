#!/usr/bin/env bash
# GitSetu Installer
#
# Clones the GitSetu repository to ~/.local/share/gitsetu
# and symlinks the executable to ~/.local/bin/gitsetu.
#
# Usage: curl -sL https://raw.githubusercontent.com/bhaskarjha-com/gitsetu/main/install.sh | bash

set -euo pipefail

REPO_URL="${GITSETU_REPO_URL:-https://github.com/bhaskarjha-com/gideon.git}"
SHARE_DIR="$HOME/.local/share/gitsetu"
BIN_DIR="$HOME/.local/bin"

# UI Helpers
BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
RESET="\033[0m"

echo -e "\n${BOLD}─── Installing GitSetu ───${RESET}\n"

# 1. Clone or update repository
if [[ -d "$SHARE_DIR/.git" ]]; then
    echo -e "  Updating existing installation at ${CYAN}$SHARE_DIR${RESET}..."
    cd "$SHARE_DIR"
    git fetch --quiet origin
    git reset --quiet --hard origin/main
else
    echo -e "  Cloning repository to ${CYAN}$SHARE_DIR${RESET}..."
    mkdir -p "$HOME/.local/share"
    git clone --quiet "$REPO_URL" "$SHARE_DIR"
fi

chmod +x "$SHARE_DIR/gitsetu"

# 2. Setup symlinks
echo -e "  Configuring executables in ${CYAN}$BIN_DIR${RESET}..."
mkdir -p "$BIN_DIR"
if [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
    # MSYS2/Cygwin often fall back to copying files instead of symlinking if Windows Developer Mode
    # is off. A copied gitsetu binary fails to locate its lib/ directory. Use a wrapper instead.
    echo '#!/usr/bin/env bash' > "$BIN_DIR/gitsetu"
    echo "exec \"$SHARE_DIR/gitsetu\" \"\$@\"" >> "$BIN_DIR/gitsetu"
    chmod +x "$BIN_DIR/gitsetu"
    cp "$BIN_DIR/gitsetu" "$BIN_DIR/git-setu"
else
    ln -sf "$SHARE_DIR/gitsetu" "$BIN_DIR/gitsetu"
    ln -sf "$SHARE_DIR/gitsetu" "$BIN_DIR/git-setu"
fi

echo -e "\n  ${GREEN}✓ GitSetu successfully installed!${RESET}"

# 3. Path Warning
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo -e "\n  ${BOLD}Warning:${RESET} $BIN_DIR is not in your PATH."
    echo -e "  Please add the following line to your ~/.bashrc or ~/.zshrc:"
    echo -e "    ${CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}"
fi

echo -e "\n  You can now run '${BOLD}gitsetu setup${RESET}' to begin bootstrapping your identity."
echo ""
