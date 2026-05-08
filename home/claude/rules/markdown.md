---
paths:
  - "**/*.md"
---

# Markdown Preferences

## Critical: Produce markdownlint-compliant documents from the start

When creating or editing markdown documents, proactively apply these formatting rules to avoid common markdownlint errors.

## Code Blocks (MD040)

- **Always specify language** for fenced code blocks
- Use ` ```text ` for plain text, diagrams, or non-code content
- Use ` ```bash `, ` ```python `, ` ```yaml `, etc. for code
- Never use bare ` ``` ` without a language identifier

## Headings (MD036, MD024)

- **Use proper heading syntax** (`#`, `##`, etc.) - never use **bold** as a heading replacement
- **Make headings unique** - if you need multiple "Technical Prerequisites" sections, differentiate them:
  - Good: `### 1. Technical Prerequisites (Protocol)` and `### 1. Technical Prerequisites (CI/CD)`
  - Bad: `### 1. Technical Prerequisites` (repeated)
- Use emphasis (**bold**, *italic*) for inline content only, not section headers

## Lists and Spacing (MD031, MD032)

- Add blank lines before and after:
  - Fenced code blocks
  - Lists (both ordered and unordered)
  - Blockquotes
- Exception: No blank line needed between list items

## Structure

- Use consistent heading hierarchy (don't skip levels: `##` → `####`)
- Use consistent list markers within a section (all `-` or all `*`, not mixed)
- Keep line length reasonable (aim for <100 chars where possible, <120 hard limit)

## Common Errors to Avoid

- Using **Bold Text** as a heading
- Code blocks without language: ` ``` `
- Missing blank lines around lists or code blocks
- Duplicate heading text without differentiation

## Additional Rules

- When content includes emoji, ensure emoji renders by using valid markdown markup
- Lint with .vscode settings where available
- Use user-level configuration to detect settings if no project settings are available
