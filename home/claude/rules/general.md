# General Coding Preferences

- Do not intermix "business logic" with presentation.
- Use British English for spelling words in code (e.g., `tokenise` not `tokenize`, `colour` not `color`).
- Trim trailing white space before saving files.
- Don't add redundant comments that can be easily inferred by reading the code.

## Language Policy (Commit Messages & Documentation)

**Welsh-first** (bilingual documentation encouraged):

- Any repository matching the Welsh-language git remotes defined in CLAUDE.md
- Any repository recursively under `~/github/techiaith/`
- Commit messages in Welsh
- Documentation in Welsh (bilingual Welsh + English preferred where appropriate)

**English only**:

- Any repository recursively under `~/github/mgrbyte/`
- Standalone packages/submodules (candidates for public release to PyPI, etc.)
- Commit messages in English
- Documentation in English

**Conversations**: Always in English, with a Welsh farewell when signing off:

- "Nos da!" — good night (evening/night only)
- "Hwyl!" — bye (informal, any time)
- "Wela chdi wedyn" — see you later
- "Hwyl am yr tro" — bye for now

## No Quick Fixes

Never suggest quick/hacky workarounds. Always propose the proper fix, even if it takes longer. The user prefers reproducible, correct solutions over expedient ones that accumulate technical debt.

## Pre-existing Issues

Never dismiss a discovered issue as "pre-existing, not from our changes" and move on.
Pre-existing or not, flag it and fix it immediately upon discovery.
Commit the fix separately from the current work, but do not defer it.

## Git History

Never suggest `git commit --amend` for commits that have already been pushed. Always create a new commit instead. Force pushing rewrites shared history and disrupts the workflow, even when "safe".

## Remote Command Visibility

Always paste the full output of every `remoteExec` command into your text response. No exceptions. The user cannot see MCP tool results in their UI — only your text output is visible to them. After every `remoteExec` call, copy the output verbatim into a code block in your response.

## Plan File Management

- **Never overwrite or replace** existing plan files in `~/.claude/plans/`. Always create a new file for a new plan.
- **Archive completed plans** by moving them to the path defined in CLAUDE.md under "Plan Archive Location".
- Plan files are immutable records of decisions made — they should not be repurposed for unrelated work.
