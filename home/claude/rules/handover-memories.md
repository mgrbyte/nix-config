# Handover Memories

## Storage

When the user requests a handover memory, write it to the project's Serena memory system, NOT Claude Code's internal memory system (`~/.claude/projects/*/memory/`).

Use `mcp__serena__write_memory` to create memories at `.serena/memories/$memory_name` in the active project directory.

## Why

Claude Code's internal memory files are stored in encoded project paths that are not version controlled. Claude Code has a pattern of overwriting plans and memories destructively — the original content is permanently lost. Serena memories live in the project directory where they can be version controlled and are safe from accidental overwrites.

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
