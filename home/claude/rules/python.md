---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
---

# Python Preferences

## Style & Formatting

- Always 4 spaces for indentation
- Use ruff for linting and formatting
- Use ty (Astral's type checker) for type-checking
- Follow PEP8 and Python conventions
- Write methods and functions without introducing blank lines unless the logic is particularly complex
- Avoid inline imports unless strictly required (resolving circular imports as a very last resort)
- Use relative imports (`from .module import`, `from . import`) for intra-package imports within `src/` code
- NEVER add blank lines in function or method definitions, UNLESS the code is sufficiently complex to warrant doing so.
- DO NOT add inline `# type: ignore` to suppress typing errors UNLESS it's the only option/last resort.
- Separate module level constants with blank lines.

## Symbol Visibility

- **Public by default.** A symbol gets a leading underscore ONLY when it is a genuine implementation
  detail that (a) would never sensibly be imported by another module, AND (b) is not part of a
  contract asserted by a test that imports it directly. Python "protected" is only a marker —
  nothing prevents import — so don't underscore helpers reflexively.

## Symbol Ordering

Order symbols in every namespace (module body and class body) by **kind first, then visibility, then
name** — "the type of symbol trumps its naming":

1. **Kind** (primary). Module: attrs → CONSTANTS → functions → classes. Class: data attributes →
   dunder methods → properties → (non-dunder) methods.
2. **Visibility** (within a kind): `__dunder__` → `__mangled` → `_protected` → public.
3. **Name** (within a (kind, visibility) bucket): alphabetical. Public lowercase precedes public
   UPPERCASE (`attr` before `ATTR`) — custom precedence, not an ASCII sort.

Apply where possible, not dogmatically. Pragmatic exceptions: pydantic/dataclass require non-default
fields before defaulted ones (alpha within each group, not across); runtime definition-order
dependencies; circular-import resolution.

**Attr vs CONSTANT (casing).** `UPPER_CASE` is for true constants — immutable values (field-name
strings, frozen taxonomies). A module-level **singleton / cache instance** (a memoised
`tldextract.TLDExtract()`, a compiled client, a connection pool, etc.) is an *attr*: name it
**lowercase**, `_`-prefixed when it's a protected impl detail — e.g. `_tldextract`, not `_EXTRACT`.
Casing follows kind, so this also sets the ordering slot (attrs sort before CONSTANTS).

## Imports

The decision is "does qualifying with the module name earn its place at the call site?" — not a
count threshold.

- **Qualify** (`import module` / `from pkg import module`, then `module.name`) when the module name
  adds recognition: `os`, `io`, `sys`, `json`, `re`, `time`, `subprocess` (strong always-qualify
  idiom), `pa`/`pd`.
- **`from module import name`** when the name is self-documenting and the module would be noise:
  `Path`, `dataclass`, `Callable`, `from __future__ import annotations`, `typing` names.
- **Hard overrides** (beat the aesthetic call): (1) mockability — if a function is monkeypatched in
  tests, `import module; module.func` so `patch("module.func")` works at the definition site;
  (2) collision — never `import X as _Y`, import the module and qualify; (3) circular imports —
  `import module`.
- **One style per imported module per file** — never mix `from m import a` with `import m; m.b` for
  the same `m`.
- (Intra-package imports within `src/` stay relative — see Style & Formatting above.)

## Literals & Single-Value Operations

- **Ordering within literals:** alphabetise elements only when their order carries no meaning (sets,
  `frozenset`s, choice/label lists, flag-style kwargs dicts). Keep semantic order for
  order-significant literals (pipeline/priority sequences; dicts with a natural id → attributes →
  timestamps reading order).
- **Dict spreads are load-bearing under key collision** — later keys win: `{**base, "k": v}`
  overrides `base["k"]`, whereas `{"k": v, **base}` lets `base` win. Don't reorder a spread that
  encodes override precedence.
- **Excluding a single element:** use the collection's native removal, not a `!=` comprehension
  filter — `list.remove(x)` for a known list where `x` is present; `dict.pop(key, None)` for dicts /
  schema-metadata (safe even if the key is absent).

## Data Structures

- **Prefer a `NamedTuple` or `@dataclass` over an anonymous tuple (or bare dict) for any structured
  value** — name the fields and type them. This is non-negotiable for data structures on a
  design/implementation **critical path**: values returned across a function/module boundary,
  persisted, or central to a stage/pipeline's contract. Anonymous tuples force positional unpacking
  and hide intent (`x[2]` vs `x.version`). Bare tuples are acceptable only for trivial, local,
  short-lived pairs with self-evident positional meaning.

## Regular Expressions

- **Documenting a complex + non-obvious regex:** use `re.VERBOSE` with a comment per component,
  and/or compose it from named **non-capturing** sub-pattern variables. Apply only when the regex is
  both complex AND non-obvious to an experienced programmer — trivial one-liners stay inline. The bar
  is reader-relative; when unsure, ask rather than convert unilaterally.
- **Named capture groups** only when the consuming code reads those captures (then named
  `(?P<area>…)` beats numbered `\g1`, which forces the reader to count groups). If captures aren't
  consumed, keep groups non-capturing `(?:…)`.

## Modern Python (3.11+)

- Use `foo | None` instead of `Optional[foo]`
- Use `dict[str, str]` instead of `Dict[str, str]`
- Don't manually maintain `__version__` in `__init__.py` - use pyproject.toml as single source of truth

## Project Management

- Use uv to manage Python projects, prefer `uv sync` over `uv pip`
- Use uv sync for pyproject.toml based projects unless good reason not to
- Use uv/astral.io images for Docker projects when the main application is Python
- Strive to avoid use of system Python
- Configure type checker to ignore missing library stubs in pyproject.toml as needed

## Namespace Packages, `__init__.py` & Indirection

- Top-level namespace packages (like `techiaith`): no `__init__.py`; add a `py.typed` marker;
  configure the type checker for namespace packages as needed.
- **Prefer no `__init__.py` below that too** — remove ones not strictly required (a docstring-only
  `__init__.py` adding nothing over the directory name is needless). Keep one only where strictly
  required (some test-collection / tooling cases); determine "required" empirically — build + import
  + type-check + test suite all stay green.
- **Avoid `__all__`.** Its only real effect is on `import *` (itself an anti-pattern), so otherwise
  it is pure indirection. Use only where absolutely necessary.
- **No re-export / forwarding** of a submodule's symbols up through a package `__init__` — it creates
  a second import path for one symbol. Consumers import the canonical module path and qualify (see
  Imports).

## Library Preferences

- Use existing library preferences for tasks (e.g., pydantic for validation/modeling/settings)
- **Naming convention for pydantic_settings**: Use `settings.py` (not `config.py`) for modules containing pydantic settings classes, and `settings/` directory for YAML/config files
- Use pyyaml for YAML and orjson for JSON

## Pre-commit Checks

Run the following steps before every git commit:

1. ruff check
2. ruff format (if required)
3. ty check (via `uvx ty check`)
4. pytest (if project has tests)

Ensure all linting and typing errors are fixed before committing with git.

## Testing

- **Do NOT write tests that only verify pydantic model/settings behaviour.** Pydantic is well-tested. Tests like "does this field have a default" or "does env var loading work" test pydantic, not our code. Only test pydantic models if there's custom validation logic or computed fields with real business logic.
- For multi-service projects (storage stacks, pipelines, external APIs), at least one test must exercise the real stack. A black-box test running with `--limit N` against the actual network catches more bugs than mocked unit tests.
- Prefer `@pytest.mark.unit` vs `@pytest.mark.integration` markers to distinguish fast vs slow tests.
- NEVER add comments when the code is self-describing and simple.

## CLI Applications (typer)

- Use typer instead of click for CLI applications
- Use `from rich import print` instead of creating Console instances
- Prefer decorator-based command registration: `@app.command()` over manual registration
- Pattern: Define `app` in `cli/__init__.py`, then import command modules that register themselves via decorators
- Avoid deeply nested command structures when a flat structure is clearer
- Note: Typer auto-promotes single commands to be the default (no subcommand needed)
