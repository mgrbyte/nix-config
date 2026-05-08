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
- NEVER add blank lines in function or method definitions, UNLESS the code is sufficiently complex to warrant doing so.
- DO NOT add inline `# type: ignore` to suppress typing errors UNLESS it's the only option/last resort.

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

## Namespace Packages (like `techiaith`)

- No `__init__.py`
- Add `py.typed` marker file
- Configure type checker for namespace packages as needed

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
