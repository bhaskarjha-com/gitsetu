# Core CLI Audit Report (Final Revision)

*Note: This report supersedes previous drafts following exhaustive terminal simulations.*

## 1. The Dual-Strategy Architecture is Mandatory
It is a common misconception that Git's native `includeIf` and `core.sshCommand` are sufficient to handle multi-identity routing. They are not.
*   **The Flaw in Pure Git:** When an external package manager (e.g., `go get`, `npm`, `terraform`) clones a dependency, it targets a global cache directory (e.g., `~/.go/pkg/mod/`). Because the target directory falls outside the mapped `includeIf` workspace, Git silently drops the `core.sshCommand`, causing authentication to fail.
*   **The Necessity of `~/.ssh/config`:** Providing OS-level SSH host aliases (e.g., `github-pro`) is the *only* mathematically sound way to allow developers to explicitly target an identity when cloning outside of a mapped workspace. 

**Verdict:** The GitSetu dual-strategy architecture is brilliant, robust, and mandatory.

## 2. The True Blunder: Inline Mutation
While the strategy is correct, the execution is dangerous. Currently, GitSetu uses `awk` to parse, rip open, and mutate the user's global `~/.ssh/config` inline. 
**Critique:** This is a ticking time bomb. Complex SSH configurations, power outages during atomic moves, or unexpected whitespace can lead to the corruption of the user's entire network access configuration. This violates the principle of "Zero-Trust".

## 3. The Paradigm Shift: OpenSSH `Include`
OpenSSH 7.3 (released in 2016) introduced the `Include` directive. We can achieve true Zero-Trust isolation.
1. GitSetu must stop mutating `~/.ssh/config` inline.
2. All GitSetu aliases should be written to an isolated file: `~/.config/gitsetu/ssh_config`.
3. GitSetu only needs to append a single line to the **absolute top** of the user's `~/.ssh/config`:
   `Include ~/.config/gitsetu/ssh_config`

This guarantees GitSetu's aliases are evaluated correctly ("first-match wins") without ever jeopardizing the user's personal configuration blocks.

## 4. Distribution: The "Curl Pipe Bash" Dead End
The distribution model promotes `curl -sL ... | bash`. While great for bootstrapping, it is a dead end for a security tool. When we release critical patches (e.g., FIDO2 updates), users will never receive them.
**Critique:** A security orchestrator without an auto-update mechanism is inherently insecure over time. We must build a native `gitsetu update` command.
