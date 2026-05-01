#!/bin/bash
# Session tracker - tracks tool usage per session
# Trigger: PreToolUse (fires before every tool call)
# Overhead: ~5-20ms (file append only)
set -euo pipefail

VAULT_PATH="${AGENTIC_OS_VAULT:-$HOME/Documents/agentic-os}/00_System/sessions"
# Capture stdin to see what data we get
HOOK_INPUT=""
if [ ! -t 0 ]; then
    HOOK_INPUT=$(cat 2>/dev/null || true)
fi

# Try to extract tool name from JSON input or env var
TOOL_NAME=""
if [ -n "$HOOK_INPUT" ] && echo "$HOOK_INPUT" | grep -q '"tool"'; then
    TOOL_NAME=$(echo "$HOOK_INPUT" | sed 's/.*"tool":"\([^"]*\)".*/\1/')
elif [ -n "$HOOK_INPUT" ] && echo "$HOOK_INPUT" | grep -q '"tool_name"'; then
    TOOL_NAME=$(echo "$HOOK_INPUT" | sed 's/.*"tool_name":"\([^"]*\)".*/\1/')
elif [ -n "${CLAUDE_TOOL_NAME:-}" ]; then
    TOOL_NAME="$CLAUDE_TOOL_NAME"
fi

# Skip logging if we can't get a real tool name
[ -z "$TOOL_NAME" ] && exit 0

# Per-session file: each `claude` run gets its own file
# Use PPID (parent process ID) - stable across all hooks in same Claude session
if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
    SESSION_ID="$CLAUDE_SESSION_ID"
else
    SESSION_ID="$(date +%Y%m%d)-$PPID"
fi

# Extract project name from working directory
PROJECT_NAME="${PWD##*/}"
DIR_HASH=$(echo "$PWD" | md5 | cut -c1-6)

LOCK_FILE="/tmp/claude-session-$SESSION_ID.lock"

# Ensure vault directory exists
mkdir -p "$VAULT_PATH"

# Check if session was already named by user-prompt-tracker
if [ -f "$LOCK_FILE" ] && [ -s "$LOCK_FILE" ]; then
    STORED_ID=$(cat "$LOCK_FILE")
    if [ -n "$STORED_ID" ] && [ "$STORED_ID" != "1" ]; then
        SESSION_ID="$STORED_ID"
    fi
fi

SESSION_FILE="$VAULT_PATH/$SESSION_ID.md"

# Only create session file once (first tool use)
if [ ! -f "$LOCK_FILE" ]; then
    touch "$LOCK_FILE"
    mkdir -p "$VAULT_PATH"

    # Create session note with minimal visible frontmatter
    cat > "$SESSION_FILE" << EOF
---
date: $(date +%Y-%m-%d)
title: Untitled
project: $PROJECT_NAME
status: active
tags: [claude-memory, project/$PROJECT_NAME]
time: $(date +%H:%M:%S)
---

# Session $(date +%H:%M)

EOF
fi

# Append tool usage to session log
echo "- $(date +%H:%M:%S): \`$TOOL_NAME\`" >> "$SESSION_FILE"

exit 0
