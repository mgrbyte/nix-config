# Testing Patterns

## call_fut / call_mut / call_cmd Convention

Originates from Chris McDonough's Pyramid project testing guidelines
(<https://pylonsproject.org/community-unit-testing-guidelines.html>),
adopted with snake_case naming (never camelCase).

- **call_fut** — call function under test (deferred import of the function)
- **call_mut** — call module under test
- **call_cmd** — call command under test (for typer CLI commands)

Defer imports to test execution time. This prevents import failures from blocking
test discovery and provides a single point of change if the import path moves.

```python
class TestMyFunction:
    @staticmethod
    def call_fut(*args, **kwargs):
        from mypackage.module import my_function
        return my_function(*args, **kwargs)

    def test_returns_expected_value(self):
        result = self.call_fut("input")
        assert result == "expected"
```

## Key Principles

- One test class per function/method under test
- Each test method exercises one set of preconditions
- Minimise shared state — use helpers returning local variables, not `self` attributes
- Descriptive test method names that clarify intent

## Test Directory Convention

Unit tests mirror the source tree: `tests/unit/techiaith/cli/test_ui.py`
for `src/techiaith/cli/ui.py`.
