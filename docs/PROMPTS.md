# gitsetu — Prompt Library

> **What this is**: Copy-paste prompts for a brand new AI session with ZERO conversation history.
> Each prompt is self-contained — it tells the AI where the code is, what files to read, what standards to follow, and exactly what to do.
>
> **How to use**: Copy the entire prompt block (between the `---` markers) and paste it as your first message in a new session.

---

## Table of Contents

1. [Full Codebase Audit](#1-full-codebase-audit)
2. [Add a New Feature](#2-add-a-new-feature)
3. [Fix a Bug](#3-fix-a-bug)
4. [Add Tests](#4-add-tests)
5. [Improve Documentation](#5-improve-documentation)
6. [Prepare a Release](#6-prepare-a-release)
7. [Security Audit](#7-security-audit)
8. [Add New Platform Support](#8-add-new-platform-support)
9. [Resume & Portfolio Update](#9-resume--portfolio-update)
10. [Competitive Analysis Refresh](#10-competitive-analysis-refresh)
11. [Live Setup Test](#11-live-setup-test)
12. [CI/CD Improvements](#12-cicd-improvements)
13. [Code Refactor / Cleanup](#13-code-refactor--cleanup)
14. [Onboard Yourself (General Context)](#14-onboard-yourself-general-context)
15. [Brutal Security & Concurrency Audit](#15-brutal-security--concurrency-audit)

---

## 1. Full Codebase Audit

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/

Before doing anything, read these files to understand the project:
- /media/sf_dev/pro/gitsetu/README.md
- /media/sf_dev/pro/gitsetu/docs/ARCHITECTURE.md
- /media/sf_dev/pro/gitsetu/lib/core.sh (for constants and state)

Then perform a thorough technical audit:

1. Run all tests: `for f in /media/sf_dev/pro/gitsetu/tests/test_*.sh; do bash "$f" 2>/dev/null; done`
2. Run ShellCheck (if available): `shellcheck /media/sf_dev/pro/gitsetu/gitsetu /media/sf_dev/pro/gitsetu/lib/*.sh`
3. Check for bash 4+ violations (this project MUST be bash 3.2 compatible):
   `grep -rn 'declare -A\|mapfile\|readarray\|\${.*,,\}\|\${.*\^\^\}' /media/sf_dev/pro/gitsetu/lib/ /media/sf_dev/pro/gitsetu/gitsetu`
4. Check for unquoted variables and security issues
5. Verify all functions have documentation comments
6. Cross-check README test count matches actual test count
7. Verify CHANGELOG version matches GITSETU_VERSION in lib/core.sh
8. Check the module dependency graph in ARCHITECTURE.md matches actual source imports

Standards:
- Bash 3.2 compatible (no associative arrays, no mapfile, no ${var,,})
- All variables must be quoted
- All output to stderr (>&2), stdout kept clean
- Managed block markers for idempotent config file updates

Create an audit report artifact with: findings, severity, and specific fix recommendations.
Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 2. Add a New Feature

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/

Before doing anything, read these files IN ORDER to understand the project:
1. /media/sf_dev/pro/gitsetu/README.md (what the tool does)
2. /media/sf_dev/pro/gitsetu/docs/ARCHITECTURE.md (how it's built)
3. /media/sf_dev/pro/gitsetu/lib/core.sh (constants, state arrays)
4. /media/sf_dev/pro/gitsetu/gitsetu (main script — note the CRLF self-healing block and gitsetu_source pattern)

I want to add this feature: [DESCRIBE YOUR FEATURE HERE]

Rules you MUST follow:
- Bash 3.2 compatible: NO declare -A, NO mapfile, NO ${var,,}, NO |&
- All variables must be quoted — no word splitting bugs
- All user-facing output goes to stderr (>&2) using print_* functions from lib/ui.sh
- New functions MUST have a doc comment (purpose, usage, return value)
- If modifying user config files, use managed block markers (# [gitsetu:managed:start/end])
- Source new lib files via gitsetu_source() in the main gitsetu script (NOT direct source)

After implementing:
1. Write tests in tests/test_<module>.sh following the existing pattern (see tests/helpers.sh)
2. Run all tests: `for f in /media/sf_dev/pro/gitsetu/tests/test_*.sh; do bash "$f" 2>/dev/null; done`
3. Update README.md (CLI reference table, project structure if new files)
4. Update docs/ARCHITECTURE.md if adding new modules
5. Update CHANGELOG.md

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 3. Fix a Bug

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/

Read these files to understand the project:
- /media/sf_dev/pro/gitsetu/docs/ARCHITECTURE.md
- /media/sf_dev/pro/gitsetu/lib/core.sh

The bug is: [DESCRIBE THE BUG, HOW TO REPRODUCE, EXPECTED vs ACTUAL BEHAVIOR]

Follow this process:
1. First, understand the relevant module by reading the lib/*.sh file involved
2. Write a FAILING test that reproduces the bug in tests/test_<module>.sh
3. Fix the bug in the lib file
4. Run the test to confirm it passes
5. Run ALL tests to confirm no regressions: `for f in /media/sf_dev/pro/gitsetu/tests/test_*.sh; do bash "$f" 2>/dev/null; done`
6. Update CHANGELOG.md with the fix

Rules:
- Bash 3.2 compatible (no declare -A, mapfile, ${var,,})
- All variables quoted
- Don't break existing tests

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 4. Add Tests

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/

Read these files to understand the testing approach:
- /media/sf_dev/pro/gitsetu/tests/helpers.sh (test framework: assertions, isolated HOME)
- /media/sf_dev/pro/gitsetu/tests/test_validate.sh (example of well-written tests)
- /media/sf_dev/pro/gitsetu/tests/test_integration.sh (example of end-to-end tests)

Current coverage: 74 tests across 7 test files. I want to improve coverage.

Identify gaps by:
1. Reading each lib/*.sh file and listing functions without corresponding tests
2. Checking edge cases not covered (empty input, special characters, permission errors)
3. Looking for untested subcommands (status, verify, guard)

Then write new tests following these patterns:
- Use setup_test_home() for any test that touches files
- Test functions return 0 (pass) or 1 (fail)
- Register with: run_test "description" function_name
- Use assert_* helpers: assert_equals, assert_contains, assert_file_exists, assert_file_contains, assert_exit_code
- Tests MUST NOT touch real ~/.ssh or ~/.gitconfig

Run all tests after adding: `for f in /media/sf_dev/pro/gitsetu/tests/test_*.sh; do bash "$f" 2>/dev/null; done`
Update README.md test count.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 5. Improve Documentation

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/

Read ALL documentation files:
- /media/sf_dev/pro/gitsetu/README.md
- /media/sf_dev/pro/gitsetu/docs/ARCHITECTURE.md
- /media/sf_dev/pro/gitsetu/docs/TROUBLESHOOTING.md
- /media/sf_dev/pro/gitsetu/docs/VISION.md
- /media/sf_dev/pro/gitsetu/CONTRIBUTING.md
- /media/sf_dev/pro/gitsetu/CHANGELOG.md

Also read the actual code to verify accuracy:
- /media/sf_dev/pro/gitsetu/gitsetu (subcommands, help text)
- /media/sf_dev/pro/gitsetu/lib/core.sh (version, constants)

Cross-check and fix:
1. Test count in README matches actual (run tests to count)
2. CLI reference table matches actual subcommands in main()
3. Module diagram in ARCHITECTURE.md matches actual lib/*.sh files
4. CHANGELOG version matches GITSETU_VERSION in core.sh
5. Platform table matches detect_os() in platform.sh
6. Bash 3.2 compat table in CONTRIBUTING.md is complete
7. All file paths and cross-references between docs are valid
8. FAQ answers are technically accurate

Also assess quality:
- Is README compelling for a portfolio project?
- Are troubleshooting entries covering real user pain points?
- Is the architecture doc useful for a new contributor?

Create an artifact with all findings and fix everything in-place.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 6. Prepare a Release

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/

Read these files first:
- /media/sf_dev/pro/gitsetu/lib/core.sh (current GITSETU_VERSION)
- /media/sf_dev/pro/gitsetu/CHANGELOG.md (current release notes)

I want to prepare release v[VERSION]. Execute this checklist:

1. Update GITSETU_VERSION in lib/core.sh to the new version
2. Update CHANGELOG.md with all changes since last release
3. Run full test suite: `for f in /media/sf_dev/pro/gitsetu/tests/test_*.sh; do bash "$f" 2>/dev/null; done`
4. Run ShellCheck if available: `shellcheck /media/sf_dev/pro/gitsetu/gitsetu /media/sf_dev/pro/gitsetu/lib/*.sh`
5. Verify `bash /media/sf_dev/pro/gitsetu/gitsetu --version` shows new version
6. Update README.md test count if tests were added
7. Verify all docs are current (cross-check version references)
8. Show me the git commands to tag and push the release

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 7. Security Audit

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/
It generates SSH keys and modifies ~/.gitconfig and ~/.ssh/config.

Read the code:
- /media/sf_dev/pro/gitsetu/lib/ssh.sh (SSH key generation)
- /media/sf_dev/pro/gitsetu/lib/gitconfig.sh (config file writing)
- /media/sf_dev/pro/gitsetu/lib/guard.sh (pre-commit hook — runs on every commit)
- /media/sf_dev/pro/gitsetu/lib/backup.sh (backup management)

Audit for:
1. File permissions: Are SSH keys created with chmod 600? Is ~/.ssh/config 600?
2. eval/exec usage: Any eval with user-supplied input? (should be zero)
3. Input injection: Can profile labels/emails inject into config files?
4. Temp file safety: Are temp files created securely (mktemp)?
5. Backup exposure: Could backups leak sensitive data?
6. Guard hook: Does it make any network calls? (should not)
7. Path traversal: Can user input escape intended directories?
8. Race conditions: Any TOCTOU issues in file operations?

Also check:
- `grep -rn 'eval\|exec ' /media/sf_dev/pro/gitsetu/lib/ /media/sf_dev/pro/gitsetu/gitsetu`
- `grep -rn 'curl\|wget\|nc ' /media/sf_dev/pro/gitsetu/lib/`
- `grep -rn 'chmod' /media/sf_dev/pro/gitsetu/lib/`

Create a security audit report with severity ratings and remediation steps.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 8. Add New Platform Support

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/

Read these files:
- /media/sf_dev/pro/gitsetu/lib/platform.sh (current OS detection and path normalization)
- /media/sf_dev/pro/gitsetu/docs/ARCHITECTURE.md (platform design)

I want to add support for: [PLATFORM NAME — e.g., "FreeBSD", "Docker containers", "Codespaces"]

Steps:
1. Add detection logic to detect_os() in lib/platform.sh
2. Add prerequisite install guidance to get_install_guidance()
3. Update get_gitdir_keyword() if path matching differs on this platform
4. Update get_ssh_agent_advice() for platform-specific SSH agent setup
5. Test path normalization for this platform's path format
6. Add tests to tests/test_platform.sh
7. Update README.md platform support table
8. Add platform section to docs/TROUBLESHOOTING.md
9. Run all tests: `for f in /media/sf_dev/pro/gitsetu/tests/test_*.sh; do bash "$f" 2>/dev/null; done`

Rules: Bash 3.2 compatible, all variables quoted, test changes don't break other platforms.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 9. Resume & Portfolio Update

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/

Read these files to understand current state:
- /media/sf_dev/pro/gitsetu/README.md (features, stats)
- /media/sf_dev/pro/gitsetu/CHANGELOG.md (what's been done)
- /media/sf_dev/pro/gitsetu/lib/core.sh (version)

Also check the existing resume artifact if it exists:
- /home/ag-deb/.gemini/antigravity/brain/16b65c7e-2531-45cf-8f76-4ec2b8f4e8f4/resume_brief.md

Run tests to get exact count: `for f in /media/sf_dev/pro/gitsetu/tests/test_*.sh; do bash "$f" 2>/dev/null; done`
Count lines: `find /media/sf_dev/pro/gitsetu/lib /media/sf_dev/pro/gitsetu/gitsetu -name "*.sh" -o -name "gitsetu" | xargs wc -l`

Then update/create the resume_brief.md artifact with:
1. Short resume entry (3-4 bullet points, quantified)
2. Extended resume entry (for DevOps/Platform roles)
3. Technical interview Q&A (5 common questions with answers)
4. Portfolio stats table (LoC, tests, platforms, key innovations)
5. Skills matrix (what this project demonstrates)

Every claim must be backed by verifiable code — no exaggeration.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 10. Competitive Analysis & Product Roadmap Generation

```
You are acting as a Lead Technical Product Manager and Principal Architect. We have built a zero-dependency, pure-bash CLI tool named **GitSetu** (currently at v1.1.1) that completely automates Git identity, SSH key management, credential brokering, and OpenSSL state encryption for multi-account developers.

I want you to conduct a brutal, zero-bias audit of our current solution, compare it against the broader market, and define our technical roadmap.

### Phase 1: Deep Contextual Audit
1. Read `README.md`, `docs/VISION.md`, and `docs/ARCHITECTURE.md` to deeply understand GitSetu's core architecture, including our "Magical Clone" capability (`includeIf` mid-flight injection), our `vboxsf`/Windows CRLF self-healing logic, our OpenSSL-backed encrypted state vault, and our native Credential Broker integration.
2. Identify our exact technical boundaries, strengths, and current limitations within the pure-bash constraints.

### Phase 2: Comprehensive Web Research
1. Use your web search tools to actively research existing Git identity management tools. Specifically look into:
   - `git-profile`
   - `gitego`
   - `karn`
   - `gguser`
   - `direnv` (how it's used for git identities)
   - 1Password's SSH & Git integration (op CLI)
   - Any other highly-starred GitHub repositories solving the "multiple git accounts" problem.
2. Analyze what features they offer that we lack, how they handle SSH key generation, and what their setup friction looks like.

### Phase 3: Artifact Generation (Feature Matrix)
Create an artifact named `competitive_matrix.md`.
1. Build a detailed Feature Matrix table comparing GitSetu against at least 4 of the top competitors you researched.
2. Include dimensions such as: Zero-Dependency, Auto SSH-Key Generation, Hook/Guard Protection, Frictionless Cloning, Cross-Platform Support, State Encryption/Backup, Idempotency, and External Integrations.

### Phase 4: Artifact Generation (Product Roadmap)
Create an artifact named `product_roadmap.md`. Based on the gaps identified in the matrix and your architectural audit, define a prioritized feature roadmap using the MoSCoW method:
1. **Must Have**: Critical features we need for a v2.0 release to absolutely dominate this niche.
2. **Should Have**: High-value features that improve UX (e.g., GitLab/Bitbucket native API support, Bash Event Plugin System).
3. **Might Have**: Ambitious features (e.g., 1Password integration, GPG commit signing automation).
*For every single feature proposed, you must include a "Difficulty of Implementation" rating (Low/Medium/High) based specifically on our strict "zero-dependency bash 3.2" constraint.*

### Execution Rules
- Do NOT modify any existing source code during this session.
- Output your findings purely through the requested markdown artifacts.
- Be brutal in your assessment. If our pure-bash constraint limits a valuable feature, call it out. 

Please begin by acknowledging this prompt and immediately starting your Phase 1 reading and Phase 2 web research.
```

---

## 11. Live Setup Test

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/

I want to do a LIVE test of the setup wizard. Guide me through:

1. First, show me the dry run: `bash /media/sf_dev/pro/gitsetu/gitsetu setup --dry-run`
2. Then run the real setup: `bash /media/sf_dev/pro/gitsetu/gitsetu setup`
   - Profile 1 (default): label=global, name=Bhaskar Jha, email=hmmbhaskar@gmail.com
   - Profile 2: label=pro, name=Bhaskar Jha, email=bhaskarjha.com@gmail.com, dir=/media/sf_dev/pro
3. After setup, verify: `bash /media/sf_dev/pro/gitsetu/gitsetu verify`
4. Check status: `bash /media/sf_dev/pro/gitsetu/gitsetu status`
5. Show me the generated files:
   - cat ~/.gitconfig
   - cat ~/.ssh/config
   - cat ~/.config/gitsetu/profiles/pro.gitconfig
   - cat ~/.config/gitsetu/profiles.conf
6. Test SSH connectivity (after I add keys to GitHub)

Note: This is a Debian 13 VM with VirtualBox shared folder at /media/sf_dev/pro/.
The gitsetu script has CRLF self-healing so it works directly on vboxsf.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 12. CI/CD Improvements

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/

Read the current CI config:
- /media/sf_dev/pro/gitsetu/.github/workflows/ci.yml

Also read:
- /media/sf_dev/pro/gitsetu/README.md (badges section)
- /media/sf_dev/pro/gitsetu/tests/helpers.sh (test framework)

I want to improve CI/CD. Consider adding:
1. Badge that dynamically shows test pass/fail from CI
2. Test output artifact upload in CI
3. Release automation (create GitHub release on tag push)
4. Dependabot or similar for Actions version pinning
5. Matrix expansion (specific macOS versions, specific bash versions)
6. ShellCheck with --severity=warning for strict linting
7. Code coverage approximation (% of lib functions with tests)

Implement what makes sense. Update the CI workflow and README badges.

Rules: Keep the CI simple — this is a bash project, not a monorepo.

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 13. Code Refactor / Cleanup

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/

Read all source files:
- /media/sf_dev/pro/gitsetu/gitsetu
- /media/sf_dev/pro/gitsetu/lib/*.sh

Look for:
1. Dead code (functions never called)
2. Duplicated logic across modules
3. Functions that are too long (>50 lines) and should be split
4. Inconsistent naming conventions
5. Missing error handling (functions that should return error codes but don't)
6. Hardcoded values that should be in lib/core.sh constants
7. Output going to stdout instead of stderr
8. Variables not declared local inside functions

Rules:
- Bash 3.2 compatible
- All variables quoted
- Don't change function signatures (tests depend on them)
- Run all tests after refactoring: `for f in /media/sf_dev/pro/gitsetu/tests/test_*.sh; do bash "$f" 2>/dev/null; done`

Use the run_command tool with Cwd=/media/sf_dev/pro/niyantra for shell commands.
```

---

## 14. Onboard Yourself (General Context)

```
I have a bash CLI project called "gitsetu" at /media/sf_dev/pro/gitsetu/

This is a zero-dependency bash 3.2+ CLI tool that automates multi-identity Git and SSH setup across Linux, macOS, and Windows.

Please read these files to fully understand the project before I give you a task:

1. /media/sf_dev/pro/gitsetu/README.md — What the tool does, CLI reference
2. /media/sf_dev/pro/gitsetu/docs/ARCHITECTURE.md — How it's built (module diagram, CRLF self-healing, managed blocks, config formats)
3. /media/sf_dev/pro/gitsetu/docs/VISION.md — Why design decisions were made
4. /media/sf_dev/pro/gitsetu/lib/core.sh — Constants, state arrays, version
5. /media/sf_dev/pro/gitsetu/gitsetu — Main script (note: CRLF self-healing block at top, gitsetu_source pattern for loading libs)

Key things to know:
- Bash 3.2 compatible (NO declare -A, mapfile, ${var,,})
- All output to stderr, prompts from /dev/tty
- Managed block markers for idempotent config updates
- Tests use isolated $HOME in /tmp (never touch real config)
- VirtualBox shared folder causes CRLF — the script self-heals at runtime
- Use Cwd=/media/sf_dev/pro/niyantra for the run_command tool

After reading, summarize your understanding and I'll give you the task.
```

---

## Tips for Using These Prompts

1. **Always copy the FULL prompt** — the context setup at the beginning is critical
2. **Replace `[PLACEHOLDERS]`** with your specific details
3. **The Cwd workaround** (`/media/sf_dev/pro/niyantra`) is needed because the workspace validator may not recognize the gitsetu path
4. **If ShellCheck isn't installed**, the AI will skip that step — install with `sudo apt install shellcheck` when you can
5. **Each prompt is self-contained** — no need to reference previous conversations

---

## 15. Brutal Security & Concurrency Audit

```
You are not auditing scripts. You are auditing a highly concurrent, state-mutating filesystem orchestrator that has just undergone a strict zero-trust security hardening. Your job is to find every way this CLI tool fails, corrupts data, leaks PII, or deadlocks — specifically targeting the new fail-closed boundaries, stale lock reapers, atomic cleanup traps, and the OpenSSL encryption engine.

**Mandatory Rules:**

**Read every file. No script is "low-risk."** Read `gitsetu`, every file in `lib/`, every file in `tests/`, `install.sh`, `uninstall.sh`, and the `Makefile`. Skip nothing. Do not assume `helpers.sh` or the new `test_*.sh` regression suites (all 123 of them) are perfectly written.

**Trace, don't just read.** We recently implemented a unified `GITSETU_CLEANUP_FILES` array and trapped it to `EXIT/SIGINT/SIGTERM`. Trace this lifecycle: What happens if `kill -9` hits exactly between the `mktemp` creation and the array registration? Does the trap inadvertently swallow exit codes (`$?`)? What happens if `mv` fails during an atomic swap but the trap still fires?

**Attack the Concurrency Reaper.** We implemented stale POSIX lock reaping (writing `$$` to `profiles.lock/pid` and checking `kill -0`). Audit this heavily: What happens if two parallel headless processes simultaneously detect a dead PID and both attempt to reap and steal the lock at the exact same millisecond? Is there a secondary race condition in the reaper itself?

**Attack the Cryptographic Vault.** We just added `gitsetu backup` and `gitsetu restore`. Audit the OpenSSL wrapper (`-pbkdf2` vs `-sha256` LibreSSL fallback). Can a malicious user inject arbitrary OpenSSL flags into the password prompt? What happens during the Pre-Flight Safety Net if the system runs entirely out of disk space while packing the `.tar.gz.enc`? Are the unencrypted temporary tarballs securely wiped via the `EXIT` trap if decryption fails mid-stream?

**Execute the mental execution tree.** Walk the execution paths. Test every flag combination in your head. Analyze it inside MSYS2 (Windows), macOS, and Linux. Look at what the CLI claims to do vs what actually ends up in the hard drive. Check the new config escaping logic: can malicious Windows paths containing single quotes, subshells (`$()`), or double-escapes (`\\\\`) break out of the `[includeIf]` sanitization?

**Think in execution flows, not scripts.** For each state change (profile creation, teardown, proxy execution, pre-commit hook, vault extraction):
* Where is the state originating? (CLI flags? TTY interactive prompt? Stale registry file? Malformed `.enc` archive?)
* What global configuration files does it touch? 
* Who else touches that state concurrently? (Git GUI clients? Background fetchers? 50 parallel GitSetu CI runs?)
* What happens when the user's existing `~/.gitconfig` is totally malformed or already contains duplicate GitSetu managed blocks?

**Think in failure modes.** For each core function:
* What happens under hyper-concurrent access (`gitsetu profile add` run 100 times per second)?
* What happens if `PROFILE_COUNT` becomes desynchronized from the actual number of files on disk?
* What happens when the underlying `git`, `ssh-keygen`, or `openssl` binary is missing, aliased, severely outdated, or prompts for an interactive TTY unexpectedly?
* What happens when a user runs `gitsetu teardown --deep` on a massive directory tree lacking read permissions?

**Audit the security boundary adversarially.** We patched the pre-commit guard to be strictly "fail-closed" (`exit 1` if configuration is missing) and pinned our GitHub Actions to strict cryptographic SHAs. Think like an attacker: Can a malicious repository craft a local `.git/config` that overrides `core.hooksPath` to completely suppress the guard? Are private keys or PII ever accidentally dumped to `stdout` or `stderr` via `set -x` or an unhandled crash during `cmd_restore`?

**Scrutinize the Array Loops.** We replaced a dangerous Bash 3.2 array slicing hack with a custom `remove_profile_at_index()` loop in `lib/core.sh`. Verify this logic perfectly preserves empty strings. Are there any math expansion edge cases where `seq 0 $((PROFILE_COUNT - 1))` breaks if a user manually corrupts the registry to 0 profiles?

**Check for dual state.** Search for cases where the same concept (e.g., "is commit signing enabled?") is stored in `profiles.conf` AND in the generated `profile.gitconfig`. Verify they stay perfectly in sync when a user runs an update or manual edit.

**Count things.** Count unquoted variables. Count `mktemp` usages vs array registrations. Count `eval` or `exec` statements. Count how many `sed` commands rely on GNU extensions instead of strict POSIX. Numbers expose vulnerabilities that casual reading misses.
```
