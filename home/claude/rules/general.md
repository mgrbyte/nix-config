# General Coding Preferences

- Do not intermix "business logic" with presentation.
- Use British English for spelling words in code (e.g., `tokenise` not `tokenize`, `colour` not `color`).
- Trim trailing white space before saving files.
- Don't add redundant comments that can be easily inferred by reading the code.

## Comments vs Commit Messages

- History belongs in the commit message, never in a comment — a comment carrying a date or a
  past-tense verb ("previously", "used to") is a commit message that escaped; move the narrative
  there and let `git blame` connect it to the line.
- Comments may state standing constraints the code cannot express — invariants and "do NOT do the
  obvious thing here" tripwires — in timeless present tense, terse, no dates.
- Trim pre-existing narrative comments opportunistically, when a change next touches their file.

## No Conversational Shorthand in Persisted Artifacts

Project and package nicknames coined in conversation (abbreviations, acronyms) stay in
conversation. In code, comments, commit messages, GitLab items (issues, MRs, notes), and Serena
memories, always write the full project/package name. The shorthand is unknown to other readers
and to future-you, and cross-project GitLab references only resolve against the real project
path, never a nickname.

## No Quick Fixes

Never suggest quick/hacky workarounds. Always propose the proper fix, even if it takes longer. The user prefers reproducible, correct solutions over expedient ones that accumulate technical debt.

## Pre-existing Issues

Never dismiss a discovered issue as "pre-existing, not from our changes" and move on.
Pre-existing or not, flag it and fix it immediately upon discovery.
Commit the fix separately from the current work, but do not defer it.

## Git History

Never suggest `git commit --amend` for commits that have already been pushed. Always create a new commit instead. Force pushing rewrites shared history and disrupts the workflow, even when "safe".
