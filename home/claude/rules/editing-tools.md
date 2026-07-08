# Editing Tools — prefer LSP/Serena for symbol-level work

Choose the editing tool by the *shape* of the change, not by habit.

## Renames → reference-aware rename, never grep + Edit

For renaming any symbol (function, class, method, variable, module attribute), use a
**reference-aware rename** — Serena `mcp__serena__rename_symbol` or emacs `lsp-rename` — which
updates the definition *and* every reference in one operation. Never rename by grepping for the name
and applying multiple `Edit`s: that misses references (and matches the name in unrelated contexts)
and is error-prone.

## Whole-symbol edits → Serena symbol tools

For rewriting a whole function/method/class body, or inserting/moving code around a symbol, prefer
Serena's symbol tools (`replace_symbol_body`, `insert_after_symbol`, `insert_before_symbol`,
`find_symbol`) over repeated `Edit` calls. They target by symbol *path*, so they avoid the
string-match ambiguity that bites when two blocks are byte-identical across different symbols.

## Localized / one-off edits → Edit

Keep the `Edit` tool for localized sub-symbol changes (a few lines, imports, a docstring, a single
expression) and one-offs, where Serena's project-activation overhead isn't worth it.

## Note

Serena needs the project activated first (`mcp__serena__activate_project`), and its LSP-backed tools
can be slow to start — so the overhead pays off for multi-site / symbol-level / rename work, not
trivial single edits.
