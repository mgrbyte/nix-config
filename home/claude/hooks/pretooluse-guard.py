#!/usr/bin/env python3
"""PreToolUse guard for Claude Code.

Guards:
- Secrets: blocks Write/Edit to sensitive file paths
- Git: blocks mutating git subcommands regardless of flags (e.g. git -C <path> commit)
- Pytest: auto-adds --tb=short -q
"""

from __future__ import annotations

import json
import logging
import re
import shlex
import sys
from pathlib import Path

LOG_FILE = Path.home() / ".claude" / "hooks" / "guard.log"
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s - %(message)s",
)

# Git subcommands that must never be run by Claude.
# Matches the "deny" list in settings.json, but catches them
# even when global git flags (e.g. -C <path>) appear before the subcommand.
DENIED_GIT_SUBCOMMANDS = frozenset({
    "commit",
    "push",
    "merge",
    "rebase",
    "reset",
    "checkout",
})

# Stash sub-subcommands that are denied.
DENIED_GIT_STASH_SUBCOMMANDS = frozenset({
    "drop",
    "clear",
})


def deny(reason: str) -> None:
    """Output deny decision (reason IS fed back to Claude)."""
    print("\U0001f4a9", file=sys.stderr)
    logging.warning(f"BLOCKED: {reason}")
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }
    print(json.dumps(output))
    sys.exit(0)


def allow_with_modified_input(reason: str, updated_input: dict) -> None:
    """Output allow decision with modified input."""
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": reason,
            "updatedInput": updated_input,
        },
        "suppressOutput": True,
    }
    print(json.dumps(output))
    sys.exit(0)


def find_git_subcommand(parts: list[str]) -> tuple[str, list[str]]:
    """Extract the git subcommand from a parsed command, skipping global flags.

    Git global flags that take an argument (-C, -c, --git-dir, --work-tree,
    --namespace, --super-prefix) consume the next token. Single flags
    (--bare, --no-pager, etc.) are skipped individually.

    Returns:
        (subcommand, remaining_args) or ("", []) if no subcommand found.
    """
    # Global flags that consume the next argument
    flags_with_arg = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--super-prefix"}
    i = 1  # skip "git" itself
    while i < len(parts):
        token = parts[i]
        if token in flags_with_arg:
            i += 2  # skip flag and its argument
        elif token.startswith("-"):
            i += 1  # skip single flag
        else:
            return token, parts[i + 1 :]
    return "", []


def check_git_command(command: str) -> None:
    """Block denied git mutating subcommands regardless of flags."""
    # Handle chained commands: split on && and ; and check each part
    for segment in re.split(r"&&|;|\|\|", command):
        segment = segment.strip()
        if not segment:
            continue
        try:
            parts = shlex.split(segment)
        except ValueError:
            continue
        if not parts or parts[0] != "git":
            continue
        subcommand, remaining = find_git_subcommand(parts)
        if subcommand in DENIED_GIT_SUBCOMMANDS:
            deny(f"Blocked: mutating git operation 'git {subcommand}' is not permitted.")
        if subcommand == "add" and remaining:
            blanket_flags = {"-A", "--all", "-u", "--update", "."}
            for arg in remaining:
                if arg in blanket_flags:
                    deny(f"Blocked: 'git add {arg}' is too broad. Add specific files instead.")
        if subcommand == "stash" and remaining:
            stash_action = remaining[0]
            if stash_action in DENIED_GIT_STASH_SUBCOMMANDS:
                deny(f"Blocked: mutating git operation 'git stash {stash_action}' is not permitted.")


def check_secrets(file_path: str) -> None:
    """Block writes to files that likely contain secrets."""
    sensitive_patterns = [".env", "credentials", "secrets", ".pem", ".key"]
    if any(p in file_path.lower() for p in sensitive_patterns):
        deny(f"Blocked: {file_path} appears to contain secrets. Manual edit required.")


DENIED_RELEASE_COMMANDS = frozenset({
    "techiaith-dev version release",
    "techiaith-dev version bump",
})


def check_release_commands(command: str) -> None:
    """Block release/version commands that must be run manually."""
    for segment in re.split(r"&&|;|\|\|", command):
        segment = segment.strip()
        if not segment:
            continue
        try:
            parts = shlex.split(segment)
        except ValueError:
            continue
        if not parts:
            continue
        # Match: uvx techiaith-dev version {release,bump}
        #    or: uv run techiaith-dev version {release,bump}
        #    or: uv run --project ... techiaith-dev version {release,bump}
        if parts[0] == "uvx":
            rest = " ".join(parts[1:])
        elif parts[0] == "uv" and "run" in parts:
            run_idx = parts.index("run")
            # Skip flags after "run" (e.g. --project ../foo)
            i = run_idx + 1
            while i < len(parts) and parts[i].startswith("-"):
                i += 2 if i + 1 < len(parts) else 1
            rest = " ".join(parts[i:])
        else:
            continue
        for denied in DENIED_RELEASE_COMMANDS:
            if rest.startswith(denied):
                deny(f"Blocked: '{denied}' must be run manually by the developer.")


def check_pip(command: str) -> None:
    """Block direct pip/pip3 usage and 'uv pip install'."""
    for segment in re.split(r"&&|;|\|\|", command):
        segment = segment.strip()
        if not segment:
            continue
        try:
            parts = shlex.split(segment)
        except ValueError:
            continue
        if parts and parts[0] in ("pip", "pip3"):
            deny("Blocked: use 'uv' instead of pip.")
        if parts and parts[0] == "uv" and "pip" in parts and "install" in parts:
            deny("Blocked: use 'uv add' or 'uv sync' instead of 'uv pip install'.")


def tweak_pytest(command: str) -> None:
    """Auto-add --tb=short -q to pytest invocations."""
    if "--tb=" in command:
        return
    pattern = r"^(uv run\s+(?:--\S+\s+)*)?pytest(\s|$)"
    if re.match(pattern, command.strip()):
        new_command = re.sub(
            r"^((?:uv run\s+(?:--\S+\s+)*)?)pytest",
            r"\1pytest --tb=short -q",
            command.strip(),
        )
        allow_with_modified_input(
            "Auto-added --tb=short -q to pytest",
            {"command": new_command},
        )


def main() -> None:
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(1)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    if tool_name in ("Write", "Edit"):
        check_secrets(tool_input.get("file_path", ""))

    if tool_name == "Bash":
        command = tool_input.get("command", "")
        check_git_command(command)
        check_release_commands(command)
        check_pip(command)
        tweak_pytest(command)

    logging.info(f"PASSED: {tool_name}")
    sys.exit(0)


if __name__ == "__main__":
    main()
