#!/usr/bin/env python3
"""Stop hook that checks for unsolicited actions, logs verbosely, outputs minimally."""

from __future__ import annotations

import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path


logger = logging.getLogger(__name__)

# Try to use anthropic SDK, fall back to simple heuristics if not available
try:
    import anthropic

    HAS_ANTHROPIC = True
except ImportError:
    HAS_ANTHROPIC = False


def log(full_message: str, violation: bool) -> None:
    """Log full message to file, output single char to sys.stdout."""
    # Output single character
    if violation:
        log_fn = logger.error
        print("X")  # Violation detected
    else:
        log_fn = logger.info
        print(".")  # All good
    log_fn(f"Violation: {violation} | message: {full_message}")


def analyze_with_api(conversation_context: str) -> tuple[bool, str]:
    """Use Anthropic API to analyze if Claude acted without waiting."""
    if not HAS_ANTHROPIC:
        return False, "anthropic SDK not installed, skipping check"

    client = anthropic.Anthropic()

    prompt = f"""Analyze this Claude Code conversation excerpt. Did Claude:
1. Ask a question then immediately proceed without waiting for an answer?
2. Continue working after context compaction without pausing for user input?
3. Start implementing before the user explained their requirements?

Conversation context:
{conversation_context[-4000:]}  # Last 4000 chars

Respond with:
- VIOLATION: [yes/no]
- REASON: [brief explanation]"""

    try:
        response = client.messages.create(
            model="claude-3-haiku-20240307",
            max_tokens=200,
            messages=[{"role": "user", "content": prompt}],
        )
        analysis = response.content[0].text
        violation = "VIOLATION: yes" in analysis.lower() or "violation:yes" in analysis.lower()
        return violation, analysis
    except Exception as e:
        return False, f"API error: {e}"


def analyze_heuristic(data: dict) -> tuple[bool, str]:
    """Simple heuristic check without API."""
    # Check if there's a transcript/context we can analyze
    transcript = data.get("transcript", "") or data.get("context", "") or ""
    # Simple patterns that suggest violations
    patterns = [
        ("asked a question then immediately", True),
        ("without waiting", True),
        ("should have paused", True),
    ]
    for pattern, is_violation in patterns:
        if pattern.lower() in transcript.lower():
            return is_violation, f"Heuristic match: '{pattern}'"
    return False, "No violation patterns detected"


def main() -> None:
    logdir = Path("~/.claude/logs").expanduser()
    logdir.mkdir(exist_ok=True)
    logging.basicConfig(
        filename=str(logdir / ".claude_violations.log"),
        level=logging.INFO,
        format="[%(asctime)s] {%(pathname)s:%(lineno)d} %(levelname)s - %(message)s",
        datefmt="%d/%m/%Y %H:%M:%S"
    )
    try:
        # Read hook input
        input_data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        input_data = {}
    # Get conversation context from hook data
    # Stop hooks receive: transcript, stopReason, etc.
    context = json.dumps(input_data, indent=2, default=str)
    # Try API analysis first, fall back to heuristic
    if HAS_ANTHROPIC and os.environ.get("ANTHROPIC_API_KEY"):
        violation, analysis = analyze_with_api(context)
    else:
        violation, analysis = analyze_heuristic(input_data)
    # Log full details, output single char
    full_message = f"Input data:\n{context}\n\nAnalysis:{analysis}"
    log(full_message, violation)


if __name__ == "__main__":
    main()
