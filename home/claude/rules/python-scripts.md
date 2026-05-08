# Python Script Rules

## No Inline Python

Never use `python -c "..."` inline scripts. They cause indentation errors when copy-pasting from terminal output.

Instead, always write a proper script file:

```python
#!/usr/bin/env python
"""Description of what the script does."""

# imports
# code
```

Then run with `uv run python scripts/scriptname.py` or similar.
