#!/bin/bash
# PostToolUse hook to auto-format Python files with ruff after Write/Edit

# Read JSON input from stdin
input=$(cat)

# Extract file_path from tool_input
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only format Python files
if [[ "$file_path" == *.py ]]; then
    uvx ruff format "$file_path" 2>/dev/null
    uvx ruff check --fix --ignore F401 "$file_path" 2>/dev/null
fi

exit 0
