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
- **Structurally arbitrary fixture values get unmistakably fake names** (`dir-a`, `stage1`) —
  never spellings of real production values, current *or* retired. A real-looking name falsely
  reads as contract coupling; a retired one additionally hides drift (a stale-vocabulary fixture
  let a real sync-path regression through review, 2026-07-09).
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

## Mocking

- Use `pytest_mock.MockerFixture` over `pytest.MonkeyPatch`
- **Precedence over local consistency**: an existing test file written with `MonkeyPatch`
  (pre-dating this rule) is NOT a reason to write new tests with it — "match the surrounding
  code" does not apply to deprecated patterns. New tests always take `mocker: MockerFixture`;
  when touching a class that uses `MonkeyPatch`, convert that class in the same change.
- Prefer `mocker.patch.object(module, "name", ...)` (definition-site, returns the mock for
  assertions) over string-path `mocker.patch("pkg.module.name")`


## Typer CLI Testing

Test typer CLIs through `techiaith.testing.invoke_cli` (from `techiaith-testing`, already
in every techiaith package's dev dependencies) — never by constructing a
`typer.testing.CliRunner` per test module.

- `invoke_cli(app, sub_cmd_args, global_options=())` places global options before the
  subcommand and stringifies every argument (`Path`s, ints, etc.).
- It returns `typer.testing.Result`: assert on `result.exit_code`, `result.stdout` and
  `result.stderr` (Click 8.2+ always separates them; `result.output` is the mixed
  terminal view — handy in failure messages).
- One test class per command, with a typed `call_cmd` (see call_fut / call_mut /
  call_cmd above); patch the modules the CLI calls with `mocker` (see Mocking above).

```python
from pytest_mock import MockerFixture
from techiaith.testing import invoke_cli
from typer.testing import Result

from mypackage import cli, widget


class TestResizeCommand:
    def call_cmd(self, args: list[str]) -> Result:
        return invoke_cli(cli.app, args)

    def test_resizes_and_prints_the_result(self, mocker: MockerFixture) -> None:
        resize = mocker.patch.object(widget, "resize", return_value=4)
        result = self.call_cmd(["resize", "--factor", "2"])
        assert result.exit_code == 0, result.output
        resize.assert_called_once_with(factor=2.0)
        assert "4" in result.stdout
```
