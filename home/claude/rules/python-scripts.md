# Python Script Rules

## Inline Python: throwaway lookups only

`python -c "..."` is allowed for a throwaway lookup that only gathers information in Claude's
own shell: reshaping JSON from an API call, counting lines, a one-off arithmetic check. It is
never used for:

- running project code (importing or invoking any of Matt's packages, pipelines or CLIs);
- commands presented for Matt to copy and run.

Those always go in a proper script file, because inline snippets cause indentation errors when
copy-pasted from terminal output and leave no record of what ran:

```python
#!/usr/bin/env python
"""Description of what the script does."""

# imports
# code
```

Run with `uv run python scripts/scriptname.py` or similar. (Matt, 2026-10-29, relaxing the earlier
blanket ban: the objection was always to project code and hand-off commands, not to lookups.)
