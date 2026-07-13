# Handover Memories

## Storage

When the user requests a handover memory, write it to the project's Serena memory system, NOT Claude Code's internal memory system (`~/.claude/projects/*/memory/`).

Use `mcp__serena__write_memory` to create memories at `.serena/memories/$memory_name` in the active project directory.

## Why

Claude Code's internal memory files are stored in encoded project paths that are not version controlled. Claude Code has a pattern of overwriting plans and memories destructively — the original content is permanently lost. Serena memories live in the project directory where they can be version controlled and are safe from accidental overwrites.

## Workflow / behavioural feedback goes in the versioned docs, NOT project Claude-memory

Cross-cutting workflow and behavioural feedback — how Claude should work, process corrections,
agreed practices, coding conventions — belongs in the version-controlled, cross-project docs
(`vibing/claude/working-with-claude.md`, or the appropriate `nix-config/.../rules/*.md`), **NOT**
in project-specific Claude-memory (`~/.claude/projects/*/memory/`).

Project Claude-memory is invisible from every other project's session, so a workflow principle
saved there is silently forgotten the moment work moves to another repo — the primary reason the
same process corrections keep recurring. Project Claude-memory is only for genuinely
project-specific facts (this repo's goals, constraints, in-flight work).

**Reflex to resist:** "let me save a memory about this" → for anything about *how we work* (or a
language/git convention), that means editing the relevant versioned doc/rule, not project memory.
Route by scope: universal working practice → `working-with-claude.md`; language/git/tooling
convention → the matching `rules/*.md`; genuinely project-specific fact → project Claude-memory.

## `.serena/project.yml` Is Untracked by Policy

`.serena/project.yml` is tool-authored: Serena regenerates its comments and migrates its own
settings schema on activation, so tracking it dirties every repo on every Serena upgrade with
diffs nobody reviews. Policy (agreed 2026-07-13): in every repo it is untracked and ignored via
`.serena/.gitignore` (entry `project.yml` — relative to that directory), after
`git rm --cached -f .serena/project.yml`. Do NOT suggest tracking it, committing its churn, or
ignoring `.serena/` wholesale — `.serena/memories/` stays version-controlled. Exception: a repo
with genuinely customised Serena config may track it, reversing the policy in that repo only.

## Serena Project Activation

- **Never activate a Serena project in a non-git-repo directory.** Before activating, verify the directory is a git repo root (contains `.git/`). If it doesn't, find the correct git repo subdirectory.
- **The correct project is the git repo being worked on**, not a parent umbrella or monorepo directory. For example, activate at `parent-dir/actual-git-repo/`, not at `parent-dir/`.
- **Always activate before writing:** Call `mcp__serena__activate_project` with the project name (from `.serena/project.yml` `project_name` field) before any `write_memory` or `edit_memory` call. Do not assume the project is already active.
- **Verify after activating:** Check that the active Serena project path matches the git repo root of the project being worked on before writing any memory.

## Remote Projects

- **Always write to the local clone, never the remote server.** When working on a remote project via `--add-dir`, Serena memories go to the local clone of that project on this Mac.
- Write to whichever project the work relates to — it does not have to be the primary working directory, but it must be local.

## Reading Memories

- **Always check the local `.serena/memories/` directory first.** Memories live in the project's git repo, not on remote servers. Even when working on a remote project via `--add-dir`, the local clone is the source of truth.
- If Serena MCP is not available (project not registered), read memories directly from `.serena/memories/` using local file tools (Read, Glob, Bash).
- Do not look on the remote server for memories — they may not have been pushed yet.

## Rules

- **Handover memories:** Always use Serena `write_memory`
- **Never overwrite** an existing memory without showing the user the changes first and getting explicit approval
- **To update** a Serena memory, use `edit_memory` (not `write_memory`) so changes are incremental
- **Read before writing:** Always read the existing memory content before proposing changes
