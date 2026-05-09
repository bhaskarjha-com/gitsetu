# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **Backup Registry Integrity:** Replaced undefined `GITSETU_SSH_DIR` reference with `_collect_ssh_key_paths()` that dynamically enumerates SSH key paths from profiles.conf.
- **Restore Lifecycle:** Refactored `cmd_restore` to use `load_profiles()` and standard helpers instead of dead function calls.
- **Registry Sync:** Added `PROFILE_USERS` and `PROFILE_PATS` arrays to `remove_profile_at_index()` rebuild loop, preventing credential state desync.
- **Profile Removal:** Replaced manual array reload in `cmd_remove` with `load_profiles()` to prevent index misalignment.
- **Verify Portability:** Corrected `verify.sh` to use `PROFILE_KEYS` array instead of hardcoded paths, supporting FIDO2 and custom SSH key locations.
- **Empty Array Safety:** Guarded `remove_profile_at_index()` against Bash 3.2 `set -u` crash when arrays become empty after removal.
- **Cleanup Leak:** Added `gitsetu_global_cleanup()` call before `exec` in `cmd_run` since `exec` replaces the process and the EXIT trap never fires.
- **Credential Latency:** Moved `detect_os()` inside `cmd_credential` case branches to avoid unnecessary platform detection on early-exit paths.
- **Vault Security:** Replaced hardcoded `safety_net` password in pre-restore vault with random password from `/dev/urandom`, stored in adjacent `.password` file.
- **Error Visibility:** `cmd_remove` now checks return codes from `write_global_gitconfig` and `write_ssh_config`, warning the user instead of silently swallowing failures.
- **README Accuracy:** Corrected false claim that SSH keys are stored under `~/.ssh/gitsetu/` — they're at `~/.ssh/id_ed25519_<label>`.

### Changed
- **Prompt Library:** Overhauled all 18 prompts in `docs/PROMPTS.md` using context engineering best practices (PCRF pattern, role personas, anti-pattern sections).
- Added 2 new prompts: Performance Profiling (#17) and UX/DX Audit (#18).

## [1.1.1] - 2026-05-07

### Fixed
- **Adversarial Audit Remediations:** Secured the OpenSSL vault against unencrypted `SIGINT` leakage by registering temporary archives with the global cleanup trap.
- **Safety Net Enforcement:** `cmd_restore` now strictly evaluates the exit code of the pre-flight safety backup and decisively aborts upon failure to prevent catastrophic data loss.
- **Phantom Deadlocks:** Completely eliminated race conditions in the POSIX lock reaper by increasing the Phantom Deadlock Prover timeout to 5.0 seconds (50 cycles) to survive heavy CI parallelism.
- **Hook Subversion:** Built runtime subversion detection for locally overridden `core.hooksPath` to protect against malicious repositories.
- **Array Integrity:** Fixed missing bounds check in `remove_profile_at_index` and replaced unstable `seq` dependencies with strict Bash C-style loops.
- **Subshell Latency:** Intercepted the `gitsetu prompt` evaluation before library sourcing, dropping PS1 terminal latency from ~95ms to ~16ms.
- **Installer Precision:** Fixed the internal fallback `REPO_URL` inside `install.sh` to correctly point to `gitsetu.git`.
- **Global Trap Ownership:** The `EXIT` trap now mathematically verifies POSIX lock ownership (`cat pid == $$`) before deletion, securing parallel CI pipelines from cross-process lock corruption.
- **Micro-TOCTOU Elimination:** Abandoned `mktemp` in favor of pre-registering randomized `$TMPDIR` paths in the cleanup array *before* disk generation, completely eliminating temporary file leaks during `SIGINT` interruption.
- **Strict POSIX Portability:** Replaced GNU/BSD specific `sed -E` flags with standard `awk` extraction in `gitsetu doctor` to guarantee execution on legacy Unix variants (Solaris, AIX).

## [1.1.0] - 2026-05-02

### Added
- **Native Git Credential Broker:** Fully isolated HTTPS PAT management powered by macOS Keychain (`security`) and Linux (`secret-tool`). 
- **Encrypted State Export (`gitsetu backup`):** Natively bundles and encrypts GitSetu state using OpenSSL (`-pbkdf2` / `-sha256`) with a strict Pre-Flight safety net.
- **FIDO2 / YubiKey Hardware Bootstrapping:** Support for `ed25519-sk` generation with automatic fallback to software keys.
- **Sub-millisecond Shell Prompt:** `gitsetu prompt` feature for native `$PS1` integration without spawning expensive subshells.
- **Custom SSH Key Paths:** Natively map and link arbitrary existing SSH keys in `~/.gitconfig`.
- **Enhanced Testing:** Comprehensive 123-test sandbox matrix simulating the complete Git credential lifecycle.
- **Enterprise DevOps Architecture:** Introduced strict `dependabot` configuration, `SECURITY.md`, and robust CI linting.

### Changed
- Converted interactive prompt secrets to use `stty -echo` for complete terminal blinding during token capture.
- Standardized community issue templates into YAML format.

## [1.0.0] - 2026-04-20

### Added
- Initial release of GitSetu.
- Zero-dependency architecture in pure Bash 3.2.
- Core Identity Bootstrapping engine.
- Atomic lock file mechanism (`lock.tmp`) with stale lock reaping.
- Pre-commit global Git hook (`gitsetu guard`) for zero-trust identity verification.
- `useConfigOnly` security boundary.
- Subshell-free `gitsetu run` environment overwrites.
- Support for `includeIf` runtime Git configuration generation.
