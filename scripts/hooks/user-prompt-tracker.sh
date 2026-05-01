#!/bin/bash
# User prompt tracker - captures user messages to session file
# Trigger: user-prompt-submit (fires on every user message)
# Overhead: ~5-20ms (file append only)
# Auto-names file based on first user message
# Renaming handled independently by session-finalizer.sh via launchd
set -euo pipefail

VAULT_PATH="${AGENTIC_OS_VAULT:-$HOME/Documents/agentic-os}/00_System/sessions"

# One file per day per project (directory)
# This ensures all work in the same project on the same day goes to one file
PROJECT_NAME="${PWD##*/}"
DIR_HASH=$(echo "$PWD" | md5 | cut -c1-6)
SESSION_ID="$(date +%Y%m%d)-${DIR_HASH}"

SESSION_FILE="$VAULT_PATH/$SESSION_ID.md"
LOCK_FILE="/tmp/claude-session-$SESSION_ID.lock"
NAMED_FILE="/tmp/claude-session-$SESSION_ID.named"

# Ensure vault directory exists
mkdir -p "$VAULT_PATH"

# Capture user message from available sources FIRST (before file creation)
USER_MSG=""
RAW_INPUT=""

if [ -n "${CLAUDE_USER_PROMPT:-}" ]; then
    RAW_INPUT="$CLAUDE_USER_PROMPT"
elif [ -n "${CLAUDE_PROMPT:-}" ]; then
    RAW_INPUT="$CLAUDE_PROMPT"
elif [ ! -t 0 ]; then
    RAW_INPUT=$(cat 2>/dev/null || true)
fi

# Extract prompt from JSON if it's JSON format
if [ -n "$RAW_INPUT" ]; then
    if echo "$RAW_INPUT" | grep -q '"prompt"'; then
        # It's JSON - extract the prompt field
        USER_MSG=$(echo "$RAW_INPUT" | sed 's/.*"prompt":"\([^"]*\)".*/\1/' | sed 's/\\n/\n/g')
    else
        USER_MSG="$RAW_INPUT"
    fi
fi

# Function to generate slug from text
generate_slug() {
    local text="$1"
    # Take first 50 chars, lowercase, replace non-alphanumeric with hyphens, trim hyphens
    echo "$text" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/[^a-z0-9]/-/g' | \
        sed 's/--*/-/g' | \
        sed 's/^-//' | \
        sed 's/-$//' | \
        cut -c1-50
}

# Create session file if this is the first prompt
if [ ! -f "$LOCK_FILE" ]; then
    touch "$LOCK_FILE"

    # Generate slug from first user message for auto-naming
    TOPIC_SLUG=""
    FIRST_WORDS=""
    if [ -n "$USER_MSG" ]; then
        # Get first line, skip if it's a file path
        FIRST_LINE=$(echo "$USER_MSG" | head -1)
        if [[ "$FIRST_LINE" != /* ]] && [[ "$FIRST_LINE" != ~/* ]] && [[ "$FIRST_LINE" != \'/* ]]; then
            FIRST_WORDS=$(echo "$FIRST_LINE" | cut -d' ' -f1-5)
        else
            # Skip file path, use second line or generic
            FIRST_WORDS=$(echo "$USER_MSG" | sed -n '2p' | cut -d' ' -f1-5)
        fi
        [ -n "$FIRST_WORDS" ] && TOPIC_SLUG=$(generate_slug "$FIRST_WORDS")
    fi

    # Use topic slug if available, otherwise fall back to PPID
    if [ -n "$TOPIC_SLUG" ] && [ ${#TOPIC_SLUG} -gt 3 ]; then
        NEW_SESSION_ID="$(date +%Y%m%d)-${TOPIC_SLUG}"
        SESSION_FILE="$VAULT_PATH/$NEW_SESSION_ID.md"
        # Store the actual session ID for other hooks to find
        echo "$NEW_SESSION_ID" > "$LOCK_FILE"
    fi

    # Create session note with minimal visible frontmatter
    # System fields (time, project_hash, session_id) stored but collapsed
    cat > "$SESSION_FILE" << EOF
---
date: $(date +%Y-%m-%d)
title: ${FIRST_WORDS:-Untitled}
project: $PROJECT_NAME
status: active
tags: [claude-memory, project/$PROJECT_NAME]
time: $(date +%H:%M:%S)
---

# ${FIRST_WORDS:-Session $(date +%H:%M)}

EOF
else
    # Read actual session file path from lock file (in case it was renamed)
    if [ -s "$LOCK_FILE" ]; then
        STORED_ID=$(cat "$LOCK_FILE")
        if [ -n "$STORED_ID" ] && [ "$STORED_ID" != "1" ]; then
            SESSION_FILE="$VAULT_PATH/$STORED_ID.md"
        fi
    fi
fi

# Append user message if we captured one
if [ -n "$USER_MSG" ]; then
    # Truncate very long messages for readability
    if [ ${#USER_MSG} -gt 2000 ]; then
        USER_MSG="${USER_MSG:0:2000}... (truncated)"
    fi

    {
        echo ""
        echo "### User ($(date +%H:%M:%S))"
        echo "$USER_MSG"
        echo ""
    } >> "$SESSION_FILE"
fi

exit 0
