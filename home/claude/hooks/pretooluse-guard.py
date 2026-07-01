#!/usr/bin/env python3
"""PreToolUse guard for Claude Code.

Guards:
- Secrets: blocks Write/Edit to sensitive file paths
- Git: allows mutating git on feature branches; blocks anything that would
  commit to, rewrite, push to, or force-update a protected branch (main/master),
  regardless of flags (e.g. git -C <path> commit)
- Pytest: auto-adds --tb=short -q
"""

from __future__ import annotations

import json
import logging
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

LOG_FILE = Path.home() / ".claude" / "hooks" / "guard.log"
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s - %(message)s",
)

# Branches Claude must never mutate. Mutating git is permitted on any other
# (feature) branch, but blocked when it would commit to, rewrite, push to, or
# force-update one of these.
PROTECTED_BRANCHES = frozenset({"main", "master"})

# Subcommands that rewrite/advance the *current* branch's history.
# Blocked only when HEAD is on a protected branch.
HISTORY_MUTATING_SUBCOMMANDS = frozenset(
    {
        "commit",
        "merge",
        "rebase",
        "reset",
    }
)

# git-add args that stage everything; too broad regardless of branch.
BLANKET_ADD_ARGS = frozenset({"-A", "--all", "-u", "--update", "."})

# checkout -b/-B and switch -c/-C (force-)create the branch named next.
BRANCH_CREATE_FLAGS = frozenset({"-b", "-B", "-c", "-C"})

# git-branch flags that delete/rename/copy/force-update an existing branch.
BRANCH_MODIFY_FLAGS = frozenset(
    {
        "-C",
        "-D",
        "-M",
        "-c",
        "-d",
        "-f",
        "-m",
        "--copy",
        "--delete",
        "--force",
        "--move",
    }
)

# Stash sub-subcommands that are denied (data loss; unrelated to branch).
DENIED_GIT_STASH_SUBCOMMANDS = frozenset(
    {
        "drop",
        "clear",
    }
)


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


def allow(reason: str) -> None:
    """Output a plain allow decision that bypasses the permission prompt."""
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": reason,
        },
        "suppressOutput": True,
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
    flags_with_arg = {
        "-C",
        "-c",
        "--git-dir",
        "--work-tree",
        "--namespace",
        "--super-prefix",
    }
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


def git_working_dir(parts: list[str]) -> str | None:
    """Return the path passed to `git -C <path>`, if any (last one wins)."""
    cwd = None
    i = 1
    while i < len(parts):
        if parts[i] == "-C" and i + 1 < len(parts):
            cwd = parts[i + 1]
            i += 2
        else:
            i += 1
    return cwd


def current_branch(cwd: str | None) -> str | None:
    """Return the checked-out branch name, or None if detached/empty/unknown."""
    command = ["git"]
    if cwd:
        command += ["-C", cwd]
    command += ["rev-parse", "--abbrev-ref", "HEAD"]
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=3)
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    branch = result.stdout.strip()
    if not branch or branch == "HEAD":  # empty repo or detached HEAD
        return None
    return branch


def on_protected_branch(cwd: str | None) -> bool:
    return current_branch(cwd) in PROTECTED_BRANCHES


def push_targets_protected(args: list[str]) -> bool:
    """True if a push would write to a protected branch on the remote."""
    positionals = []
    for arg in args:
        if arg in ("--all", "--mirror"):
            return True
        if arg.startswith("-"):
            continue
        positionals.append(arg)
    # positionals[0] is the remote; the rest are refspecs (src[:dst], leading + = force).
    for spec in positionals[1:]:
        spec = spec.lstrip("+")
        dst = spec.split(":", 1)[1] if ":" in spec else spec
        if dst.rsplit("/", 1)[-1] in PROTECTED_BRANCHES:
            return True
    return False


def checkout_creates_protected(args: list[str]) -> bool:
    """True if checkout/switch would (force-)create a protected branch."""
    for i, token in enumerate(args):
        if token in BRANCH_CREATE_FLAGS and i + 1 < len(args):
            if args[i + 1].rsplit("/", 1)[-1] in PROTECTED_BRANCHES:
                return True
    return False


def branch_modifies_protected(args: list[str]) -> bool:
    """True if `git branch` would delete/rename/copy/force-update a protected branch."""
    if not any(arg in BRANCH_MODIFY_FLAGS for arg in args):
        return False
    for token in args:
        if token.startswith("-"):
            continue
        if token.rsplit("/", 1)[-1] in PROTECTED_BRANCHES:
            return True
    return False


def check_git_command(command: str, default_cwd: str) -> None:
    """Allow git on feature branches; block anything touching a protected branch."""
    protected = "/".join(sorted(PROTECTED_BRANCHES))
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
        cwd = git_working_dir(parts) or default_cwd
        if subcommand in HISTORY_MUTATING_SUBCOMMANDS:
            if on_protected_branch(cwd):
                deny(
                    f"Blocked: 'git {subcommand}' on a protected branch ({protected}). "
                    "Switch to a feature branch first."
                )
            continue
        if subcommand == "push":
            if on_protected_branch(cwd):
                deny(f"Blocked: 'git push' from a protected branch ({protected}).")
            if push_targets_protected(remaining):
                deny(f"Blocked: 'git push' targets a protected branch ({protected}).")
            continue
        if subcommand in ("checkout", "switch"):
            if checkout_creates_protected(remaining):
                deny(
                    f"Blocked: 'git {subcommand}' would force-create a protected branch ({protected})."
                )
            continue
        if subcommand == "branch":
            if branch_modifies_protected(remaining):
                deny(
                    f"Blocked: 'git branch' would delete/rename/force-update a protected branch ({protected})."
                )
            continue
        if subcommand == "add" and remaining:
            for arg in remaining:
                if arg in BLANKET_ADD_ARGS:
                    deny(
                        f"Blocked: 'git add {arg}' is too broad. Add specific files instead."
                    )
            continue
        if subcommand == "stash" and remaining:
            stash_action = remaining[0]
            if stash_action in DENIED_GIT_STASH_SUBCOMMANDS:
                deny(
                    f"Blocked: mutating git operation 'git stash {stash_action}' is not permitted."
                )


def check_secrets(file_path: str) -> None:
    """Block writes to files that likely contain secrets."""
    sensitive_patterns = [".env", "credentials", "secrets", ".pem", ".key"]
    if any(p in file_path.lower() for p in sensitive_patterns):
        deny(f"Blocked: {file_path} appears to contain secrets. Manual edit required.")


DENIED_RELEASE_COMMANDS = frozenset(
    {
        "techiaith-dev version release",
        "techiaith-dev version bump",
    }
)


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


# Directories where any command (except deletions) is auto-approved without a
# permission prompt, keyed on the session working directory. Mirrors the Read
# allow-list in settings.json.
PROJECT_DIRS = tuple(
    str(Path(p).expanduser().resolve())
    for p in ("~/github", "~/gitlab/cyfieithu-ac-llms", "~/gitlab/mtr21pqh")
)

# Command words never auto-approved by PROJECT_DIRS — they still fall through to
# settings.json `ask`/`deny` (deletions prompt; pip is denied there).
NEVER_AUTO_ALLOW = frozenset({"pip", "pip3", "rm", "unlink"})


def within_project_dir(cwd: str) -> bool:
    """True if CWD is inside one of the auto-approve project directories."""
    if not cwd:
        return False
    try:
        real = str(Path(cwd).resolve())
    except (OSError, RuntimeError):
        return False
    return any(real == d or real.startswith(f"{d}/") for d in PROJECT_DIRS)


def maybe_auto_allow(command: str, cwd: str) -> None:
    """Auto-approve a command (except deletions) run inside a project directory.

    Runs after the deny-guards, so protected-branch git, secrets, pip and release
    blocks always take precedence. Deletions (rm/unlink) and the .venv escape
    hatch fall through to the settings.json rules so the user is still prompted.
    """
    if not within_project_dir(cwd):
        return
    if ".venv/bin" in command:
        return
    try:
        tokens = shlex.split(command)
    except ValueError:
        return
    if any(token in NEVER_AUTO_ALLOW for token in tokens):
        return
    allow("Auto-approved: command in a trusted project directory.")


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
        cwd = input_data.get("cwd") or os.getcwd()
        check_git_command(command, cwd)
        check_release_commands(command)
        check_pip(command)
        tweak_pytest(command)
        maybe_auto_allow(command, cwd)

    logging.info(f"PASSED: {tool_name}")
    sys.exit(0)


if __name__ == "__main__":
    main()
