# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-05-02

### Added
- **Native Git Credential Broker:** Fully isolated HTTPS PAT management powered by macOS Keychain (`security`) and Linux (`secret-tool`). 
- **FIDO2 / YubiKey Hardware Bootstrapping:** Support for `ed25519-sk` generation with automatic fallback to software keys.
- **Sub-millisecond Shell Prompt:** `gitsetu prompt` feature for native `$PS1` integration without spawning expensive subshells.
- **Custom SSH Key Paths:** Natively map and link arbitrary existing SSH keys in `~/.gitconfig`.
- **Enhanced Testing:** Comprehensive 121-test sandbox matrix simulating the complete Git credential lifecycle.
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
