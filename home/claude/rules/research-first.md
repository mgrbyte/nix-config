# Research Before Implementation

## Hard Gate: No Code Without Research Approval

Before writing any code or creating an implementation plan for a non-trivial task, you MUST:

1. Complete the research checklist below
2. Present a research summary to the user
3. Get explicit approval to proceed

Do NOT skip this gate. Do NOT combine research and implementation in the same step. The research summary is a deliverable that the user reviews before any code is written.

## When This Applies

- New features or integrations
- Debugging unfamiliar code or libraries
- Any task touching libraries, APIs, or codebases you haven't verified in this session
- Any task where you'd need to assume how something works

## When You Can Skip

- Single-line changes following an established pattern
- Changes where the user has already provided the exact code or approach
- Pure documentation or comment edits

## Research Checklist

Complete ALL applicable items before presenting findings:

1. **Read project docs** — README, ARCHITECTURE.md, INSTALL.md, or equivalent. Understand the project's intended design before touching code.
2. **Search existing code** — Search the current project and related packages (e.g. techiaith-*) for existing utilities, patterns, or prior art that already solve the problem.
3. **Verify library APIs** — When using a library feature, confirm the API exists and works as expected. Read the source, use `help()`, or check docs. Never assume an API exists.
4. **Check package registries** — Before writing utility code, check if a battle-tested library already does it.
5. **Read source code** — When debugging, read the relevant source code before running diagnostic commands or guessing at fixes.

## Research Summary Format

Present findings to the user as:

```
## Research Findings

**What I found:**
- [key findings from docs, existing code, library APIs]

**Existing code/libraries that can be reused:**
- [specific functions, modules, packages with file paths]

**What I still don't know:**
- [gaps, uncertainties, things I couldn't verify]

**Proposed approach:**
- [brief outline based on findings]
```

Then wait for approval before proceeding.

## Examples of Past Failures This Prevents

- Rolling own regex tokeniser instead of using `spacy_cymraeg`
- Assuming `Padding.indent` doesn't exist without checking
- Building string formatters instead of using `rich.table.Table`
- Running many M-: diagnostic commands instead of reading lsp-ui-doc.el source
- Spending 4 hours on implementation that proper upfront research would have simplified

The goal: never say "I wasn't aware of X" or "I assumed Y" after implementation.
