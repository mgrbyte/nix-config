# Git Rules

## Commit Message Formatting

- Summary line: < 80 chars, one sentence
- Body bullets start at column 0 (no indentation)
- No more than 20 lines total
- No emojis (unless addressing a rendering bug for a specific character)
- No file system paths
- No personal identifiable information
- No internal server/machine names, hostnames, or work-specific infrastructure details
- Before writing a commit message, check `git remote -v` — if the remote is a personal repo (e.g. github.com/mgrbyte), ensure the message contains no work-specific information (server names, internal project names, client names, contract details)

Example:

```text
Short summary of the change

- First bullet point
- Second bullet point
- Third bullet point
```

## Commit Message Workflow

- **cbo** = "commit buffer open" — the user has a COMMIT_EDITMSG buffer open in Emacs
- When the user says "cbo", read the COMMIT_EDITMSG to understand the staged changes, then use `mcp__emacs__eval-elisp` to insert the commit message at point-min of the buffer
- Never use Write or Edit tools on `.git/COMMIT_EDITMSG` — always use Emacs MCP

**Not:**

```text
Short summary of the change

  - Indented bullet (wrong)
  - Another indented bullet (wrong)
```

## No Mutating Git via Remote MCP

**NEVER** run mutating git commands (`git add`, `git commit`, `git push`, `git reset`, `git checkout`, `git rebase`, `git merge`, `git stash`, `git tag`, `git branch -d/-D`) via `remoteExec` or any other MCP tool. This bypasses the user's local hooks that gate git operations.

Instead: print the exact commands for the user to run themselves. This applies even when the commit content has been reviewed and approved — the user controls when git state changes.
