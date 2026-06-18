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
- Use inheritance with a `_Base` class to share `call_fut`/`call_mut` across
  related test classes (e.g. one subclass per noise rule, all sharing the same `call_fut`)
- Each test method exercises one set of preconditions
- Minimise shared state — use helpers returning local variables, not `self` attributes
- Descriptive test method names that clarify intent
- No inline comments as section separators — use subclasses named accordingly
- No unused imports (e.g. don't import `pytest` unless using fixtures/parametrize)

## Exemplar

`techiaith-nemo-curator/tests/unit/techiaith/nemo_curator/text/stages/test_normalise.py`
demonstrates the approved style:

- Module imported at top: `from techiaith.nemo_curator.text.stages import normalise`
- `_NormaliseSentenceBase` with typed `call_fut` shared by 6 subclasses
- `TestNormaliseStageProcess` with typed `call_mut` returning `DocumentBatch`
- All methods have `-> None` annotations
- Constants imported from the module under test for assertions
- No inline section comments — class names describe the group

## Test Directory Convention

Unit tests mirror the source tree: `tests/unit/techiaith/cli/test_ui.py`
for `src/techiaith/cli/ui.py`.
