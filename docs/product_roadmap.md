# GitSetu Product Roadmap (v2.0)

*Last Updated: 2026-05-10 — Following the v1.0.0 public release, transitioning the backlog into the v2.0 development cycle.*

---

## ✅ Completed in v1.0.0 (First Official Public Release)

The following features and architectural hardening have been shipped and verified (165 automated tests, cross-platform CI):
- **Zero-Trust Identity Guard**: Enforces a strict fail-closed boundary on pre-commit; hard blocks commits if configuration is missing or tampered with.
- **Single Source of Truth (SSOT)**: Identity synchronization is guaranteed by dynamically querying isolated `.gitconfig` files, stripping dual-state variables from `profiles.conf`.
- **Unified Global Lifecycle (Filesystem Safe)**: Safe trapping of signals (`EXIT/SIGINT/SIGTERM`) to purge transient arrays, temporary files (via `mktemp` registration), and orphaned locks under all catastrophic termination scenarios.
- **POSIX Concurrency Hardening (Stale Lock Reaping)**: Atomic `mv` operations completely eliminate Time-of-Check to Time-of-Use race conditions, guaranteeing perfectly concurrent headless execution without deadlocks.
- **Bash 3.2 Array Panic Prevention**: Native C-style loops completely replace subshells, preventing catastrophic failures during empty registry states.
- **Path Injection Prevention**: Strict newline sanitization on `[includeIf]` paths prevents multi-line INI corruption of the global git configuration.
- **POSIX Subshell Optimization**: Fractured GNU `sed` extensions have been entirely replaced with native Bash regex or POSIX-compliant `sed` patterns.
- **Teardown DoS Prevention**: Bounded directory traversal safeguards the filesystem against accidental root or `$HOME` deep-cleans.
- **Masked Email Validation (GitHub No-Reply Guard)**: Strict regex validation intercepts public emails during setup.
- **Privacy Guard-Rails (`useConfigOnly`)**: Global Git identity removed; `useConfigOnly=true` forces fatal errors in unmapped directories to stop leaks.
- **Temporary Execution Override (`gitsetu run`)**: Enables instant, one-off identity hijacking for isolated commands (e.g., `gitsetu run pro -- git fetch`).
- **Global `core.hooksPath` Virtualization**: Global pre-commit hook acts as a native pass-through, preserving local developer ecosystems (Husky/Lefthook).
- **Native SSH Commit Signing**: Automates "Verified" commit badges using GitSetu-generated keys via `commit.gpgsign=true`, bypassing GPG completely.
- **Native `ssh-agent` Auto-Reloading**: Injects `AddKeysToAgent yes` (and `UseKeychain yes` on Macs) to natively force the OS SSH daemon to cache passphrases on first use.
- **Single Profile Teardown (`gitsetu remove`)**: Surgically extracts and deletes specific profiles while cleanly regenerating all global configurations.
- **FIDO2 / YubiKey Hardware Key Bootstrapping**: Automated generation of resident hardware keys (`ed25519-sk`) with safe fallback to software keys if `libfido2` is not supported on the host.
- **Shell Prompt Integration (`gitsetu prompt`)**: Ultra-fast, sub-millisecond execution for displaying the active identity within terminal `$PS1` variables without spawning subshells.
- **Custom SSH Key Naming & Paths**: Natively allows users to bypass default key schemas (`id_ed25519_<label>`) and link existing arbitrary keys via absolute path mapping in the global `.gitconfig`.
- **Git Credential Broker (PAT Management)**: Pure-Bash OS-level broker that intercepts Git HTTPS authentication streams to securely route Personal Access Tokens (PATs) directly from macOS Keychain (`security`) and Linux (`secret-tool`).
- **Encrypted State Export & Migration (`gitsetu backup`)**: Natively bundles and encrypts GitSetu state using OpenSSL (`-pbkdf2` / `-sha256`), providing a safe Pre-Flight safety net.

---

## 🔴 Must Have (Target: v2.0 Core)

### 1. Interactive Headless Expansion
**Problem:** Mass infrastructure deployments cannot easily navigate interactive TTY setup wizards.
**Solution:** Support a fully headless `gitsetu setup --blueprint <file.json>` command to seed configuration states programmatically.
**Difficulty:** Medium.

### 2. Strict SSH Agent Sandboxing
**Problem:** Loading multiple GitSetu SSH keys into the agent causes "Too many authentication failures" against GitHub/GitLab.
**Solution:** Dynamically enforce `IdentitiesOnly = yes` and carefully unmount/mount specific keys to the active agent socket context.
**Difficulty:** High.

---

## 🟡 Should Have (High-Value Integrations)

### 3. Automated SSH-Key & PAT Rotation Engine (`gitsetu rotate`)
**Problem:** Stale SSH keys and Personal Access Tokens are security liabilities, but tracking expiration dates manually is prone to error.
**Solution:** Introduce a `gitsetu rotate` subcommand that automatically checks filesystem modification times (`stat`) and warns users of expiring keys, followed by a clean re-generation process.
**Difficulty:** High (due to lack of robust external API integration in Bash).

### 4. Bash Event Plugin System
**Problem:** Users want to trigger custom scripts (e.g. notify Slack, change terminal colors) when switching identities.
**Solution:** Allow users to drop `.sh` scripts into a `plugins/` folder that execute during the `on_profile_switch` lifecycle event.
**Difficulty:** Medium.

### 5. Configuration Drift Detection (`gitsetu drift`)
**Problem:** Users might accidentally manually edit `~/.gitconfig` and break GitSetu's routing.
**Solution:** A background check that diffs the current Git config against GitSetu's expected state and warns the user.
**Difficulty:** Medium.

### 6. Backup Encryption Agility
**Problem:** Users may prefer modern encryption binaries over legacy OpenSSL wrappers.
**Solution:** Expand the OpenSSL vault logic in `gitsetu backup` to dynamically detect and support `age` or `gpg` encryption depending on host system availability.
**Difficulty:** Medium.

---

## 🟢 Might Have (v2.0 Horizon & Experimental)

### 7. 1Password SSH & Git Integration
**Problem:** Users utilizing 1Password don't want local SSH keys generated at all.
**Solution:** Detect the 1Password CLI (`op`) and automatically configure Git's `core.sshCommand` to route through their agent socket instead of generating local keys.
**Difficulty:** Very High.

### 8. Scoped Repository Auto-Discovery
**Problem:** Users want GitSetu to automatically find their misplaced `.git` repositories.
**Constraint Note:** Bash 3.2 lacks `globstar` (`**`). Using `find` on macOS will crawl network mounts. This feature *must* be strictly scoped to a single path (e.g., `gitsetu scan ~/dev`).
**Difficulty:** High.

---

## ❌ Out of Scope / Rejected

### 9. Historical Commit Sanitizer (`gitsetu sanitize`)
**Problem:** Users want to rewrite Git history to remove leaked personal emails.
**Constraint Note:** **Rejected.** The official tool `git-filter-repo` requires Python. Rewriting history in pure Bash 3.2 is wildly dangerous, highly complex, and risks catastrophic repository corruption. This violates our zero-dependency safety constraints.
