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
- No conventional-commit type prefix in the summary (`feat:`/`fix:`/`test:`/`chore:`/`refactor:`) — write a plain description (plain Welsh for Welsh-language repos — the remote is identified in CLAUDE.md). A type prefix is a smell that the change warranted its own branch (a separate unit of work), not a commit on a shared branch.

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

## Run Git Through Bash So the Guard Applies

Run all git via the `Bash` tool. The pretooluse guard (`pretooluse-guard.py`) is
branch-aware: mutating git is allowed on feature branches and blocked on
`main`/`master` (including pushes or force-branch ops that *target* them).

Never route git through an MCP tool that shells out and bypasses that guard
(e.g. Serena `execute_shell_command`, or `mcp__emacs__eval-elisp` calling
`shell-command`). There is no remote command execution tool — all dl6/remote git
is the user's (see remote-dev-workflow.md).

## Branch Creation & Upstream Discipline

- **Never create a branch with its upstream pointing at `origin/main`.** `git checkout -b X
  origin/main` silently sets upstream to `origin/main`; the user pushes from magit, and magit's
  push-to-upstream (`P u`) then pushes the feature branch's commits **directly onto main**
  (this happened 2026-07-02: a failing RED test commit landed on a repo's main and needed a
  force-with-lease restore).
- **Branch from the local ref** (after confirming it matches the remote): `git fetch` then
  `git checkout -b X main` — never name `origin/main` as the start point.
- **Push every new branch immediately after its first commit** with `git push -u origin X`,
  so the upstream always points at the branch's own remote ref. A branch must never sit
  locally with commits and a wrong (or absent) upstream waiting for a magit push.
- **Verify before hand-off:** `git status --short --branch` must show `X...origin/X`, not
  `X...origin/main`.

## Branch & Rebase Discipline

- **One unit of work per branch.** If you reach for different `feat:`/`refactor:`/`fix:` prefixes to distinguish commits on a single branch, that's the signal the work should have been split into separate branches.
- On a branch that accumulates many commits, rebase-clean **incrementally** — roughly every <10 commits — rather than one large interactive rebase at merge time (the latter is slow to analyse and conflict-prone). Squash each RED/GREEN pair into one commit soon after GREEN lands.
- **Squash mechanics (Claude's environment has no interactive rebase):** to squash the last N
  contiguous commits on a branch, use `git reset --soft HEAD~N && git commit` — HEAD moves back N
  commits while index and worktree keep the final state, and one new commit recreates the combined
  change (tree-identical to a `rebase -i` squash). Only valid for a contiguous run ending at HEAD;
  anything needing reordering, splitting, or replaying onto a new base is a true `git rebase`
  (non-interactive `git rebase <newbase>` / `--onto`) and its conflicts are resolved per-commit.
