# Testing Patterns

## call_fut / call_mut / call_cmd Convention

Originates from Chris McDonough's Pyramid project testing guidelines
(<https://pylonsproject.org/community-unit-testing-guidelines.html>),
adopted with snake_case naming (never camelCase).

- **call_fut** — call function under test
- **call_mut** — call method under test
- **call_cmd** — call command under test (for typer CLI commands)

`call_fut`/`call_mut` must use `self`, never `@staticmethod`.

Import the module under test at the top of the file, not inside
`call_fut`/`call_mut`. Prefer `from package.subpackage import module`
so call sites read as `module.function()` / `module.Class()`.

All test methods and `call_fut`/`call_mut` must have type annotations
(argument types + return type). Test methods return `-> None`.

## Key Principles

- One test class per function/method under test, or per logical group
- **Avoid leading underscores in test code** — not on classes, methods, or
  module-level helpers (no `_Base`, no `_make_one`, no `_write_artifact`); marking
  test code private is normally unnecessary. Sole exception: a symbol in a *shared*
  test module (e.g. `conftest`) that's deliberately module-private (relies on local
  state / not for use outside that module) — the only valid leading `_` in `tests/`.
- Share `call_fut`/`call_mut` and factories (e.g. `make_one`) across related test
  classes via a base class. To keep the base from being collected by pytest, name it
  with a `Test` *suffix* (e.g. `SitemapDownloaderTest` — doesn't match the `Test*`
  collection *prefix*) or, for a mixin of shared assertions, a descriptive name like
  `FoobarCommonChecks`. Real test classes keep the `Test` prefix.
- Each test method exercises one set of preconditions
- Minimise shared state — use helpers returning local variables, not `self` attributes
- Descriptive test method names that clarify intent
- No inline comments as section separators — use subclasses named accordingly
- No unused imports (e.g. don't import `pytest` unless using fixtures/parametrize)

## Exemplar

A self-contained illustration of the approved style — kept made-up on purpose so it
can never drift out of sync with live code:

```python
from mypackage import widget


class WidgetTest:  # `Test` suffix → pytest skips it; no leading underscore; shared helpers live here
    def make_one(self, **kwargs) -> widget.Widget:
        return widget.Widget(**kwargs)


class TestResize(WidgetTest):
    def call_mut(self, inst: widget.Widget, factor: float) -> widget.Widget:
        return inst.resize(factor)

    def test_doubles_width(self) -> None:
        result = self.call_mut(self.make_one(width=2), factor=2.0)
        assert result.width == 4
```

- module under test imported at the top (`from mypackage import widget`)
- shared base named with a `Test` *suffix* (`WidgetTest`) — no leading underscore, not collected
- one `Test*`-prefixed class per method/function under test, with a typed `call_mut`/`call_fut`
- every method annotated (`-> None` on test methods)

If you ever cite a *real* file instead, pin it to a git SHA (`path/to/test_foo.py @ <sha>`):
an unpinned reference to live code drifts and later reads as "doesn't exist, must be made up."

## Test Directory Convention

Unit tests mirror the source tree: `tests/unit/techiaith/cli/test_ui.py`
for `src/techiaith/cli/ui.py`.
