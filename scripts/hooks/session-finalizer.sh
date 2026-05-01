#!/bin/bash
# Session finalizer - runs independently to:
# 1. Rename sessions based on content (key term extraction)
# 2. Extract tagged content to learnings/, patterns/, decisions/
# Triggered by launchd every 5 minutes

set -euo pipefail

VAULT_PATH="${AGENTIC_OS_VAULT:-$HOME/Documents/agentic-os}/00_System/sessions"
LEARNINGS_PATH="${AGENTIC_OS_VAULT:-$HOME/Documents/agentic-os}/00_System/knowledge/learnings"
PATTERNS_PATH="${AGENTIC_OS_VAULT:-$HOME/Documents/agentic-os}/00_System/knowledge/patterns"
DECISIONS_PATH="${AGENTIC_OS_VAULT:-$HOME/Documents/agentic-os}/00_System/knowledge/decisions"
RENAME_AFTER_MINUTES=5  # Rename sessions after 5 min of content

# Common stop words to filter out
STOP_WORDS="the a an is are was were be been being have has had do does did will would could should may might must shall can to of and in that it for on with as at by from or but not this these those"

# Function to extract key terms from text
extract_key_terms() {
    local text="$1"
    local num_terms="${2:-5}"

    # Convert to lowercase, extract words, filter stop words, count frequency
    echo "$text" | \
        tr '[:upper:]' '[:lower:]' | \
        tr -cs 'a-z0-9' '\n' | \
        grep -v '^$' | \
        grep -v -w -F "$(echo $STOP_WORDS | tr ' ' '\n')" | \
        sort | uniq -c | sort -rn | \
        head -n "$num_terms" | \
        awk '{print $2}' | \
        tr '\n' '-' | \
        sed 's/-$//'
}

# Function to rename a session based on content (does NOT close it)
rename_session() {
    local file="$1"
    local basename=$(basename "$file" .md)
    local dirname=$(dirname "$file")

    # Skip if already renamed (check for 'renamed: true' in frontmatter)
    if grep -q "renamed: true" "$file" 2>/dev/null; then
        return 0
    fi

    # Skip if already has a descriptive name (not date-PID format)
    if ! [[ "$basename" =~ ^[0-9]{8}-[0-9]+$ ]]; then
        return 0
    fi

    # Extract conversation content (everything after frontmatter closing ---)
    local content=$(sed -n '/^---$/,$ p' "$file" | tail -n +2)

    # If no content yet, skip
    if [ -z "$content" ] || [ ${#content} -lt 50 ]; then
        return 0
    fi

    # Extract key terms
    local key_terms=$(extract_key_terms "$content" 4)

    # If we got meaningful terms, rename the file
    if [ -n "$key_terms" ] && [ ${#key_terms} -gt 5 ]; then
        local date_prefix=$(echo "$basename" | cut -d'-' -f1)
        local new_name="${date_prefix}-${key_terms}"
        local new_file="${dirname}/${new_name}.md"

        # Only rename if new file doesn't exist
        if [ ! -f "$new_file" ]; then
            mv "$file" "$new_file"
            file="$new_file"

            # Update session_id in frontmatter
            sed -i '' "s/session_id: .*/session_id: ${new_name}/" "$file"

            # Mark as renamed so we don't process again
            sed -i '' '/^status:/a\
renamed: true' "$file"

            # Update lock file so hooks continue to the renamed file
            local old_lock="/tmp/claude-session-${basename}.lock"
            if [ -f "$old_lock" ]; then
                echo "$new_name" > "$old_lock"
            fi

            echo "Renamed: $basename -> $new_name"
        fi
    fi
}

# Function to extract tagged content from session to appropriate folder
# Tags: [LEARNING: title], [PATTERN: title], [DECISION: title]
# Content follows until next heading (###) or tag
extract_tagged_content() {
    local file="$1"
    local content=$(cat "$file")
    local session_date=$(grep "^date:" "$file" | cut -d' ' -f2)
    local project=$(grep "^project:" "$file" | cut -d' ' -f2)

    # Extract LEARNING blocks
    echo "$content" | grep -A 100 '\[LEARNING:' | while IFS= read -r line; do
        if [[ "$line" =~ \[LEARNING:\ *([^\]]+)\] ]]; then
            local title="${BASH_REMATCH[1]}"
            local slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
            local out_file="$LEARNINGS_PATH/${session_date}-${slug}.md"

            # Skip if already extracted
            [ -f "$out_file" ] && continue

            # Capture content until next heading or tag
            local block=""
            local capturing=false
            while IFS= read -r bline; do
                if [[ "$bline" =~ \[LEARNING:\ *${title}\] ]]; then
                    capturing=true
                    continue
                fi
                if $capturing; then
                    if [[ "$bline" =~ ^###\  ]] || [[ "$bline" =~ ^\[(LEARNING|PATTERN|DECISION): ]]; then
                        break
                    fi
                    block+="$bline"$'\n'
                fi
            done <<< "$content"

            if [ -n "$block" ]; then
                cat > "$out_file" << EOF
---
date: $session_date
title: $title
project: $project
type: learning
source: $(basename "$file")
tags: [claude-memory, learning]
---

# $title

$block
EOF
                echo "Extracted learning: $title"
            fi
        fi
    done 2>/dev/null || true

    # Extract PATTERN blocks
    echo "$content" | grep -A 100 '\[PATTERN:' | while IFS= read -r line; do
        if [[ "$line" =~ \[PATTERN:\ *([^\]]+)\] ]]; then
            local title="${BASH_REMATCH[1]}"
            local slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
            local out_file="$PATTERNS_PATH/${session_date}-${slug}.md"

            [ -f "$out_file" ] && continue

            local block=""
            local capturing=false
            while IFS= read -r bline; do
                if [[ "$bline" =~ \[PATTERN:\ *${title}\] ]]; then
                    capturing=true
                    continue
                fi
                if $capturing; then
                    if [[ "$bline" =~ ^###\  ]] || [[ "$bline" =~ ^\[(LEARNING|PATTERN|DECISION): ]]; then
                        break
                    fi
                    block+="$bline"$'\n'
                fi
            done <<< "$content"

            if [ -n "$block" ]; then
                cat > "$out_file" << EOF
---
date: $session_date
title: $title
project: $project
type: pattern
source: $(basename "$file")
tags: [claude-memory, pattern]
---

# $title

$block
EOF
                echo "Extracted pattern: $title"
            fi
        fi
    done 2>/dev/null || true

    # Extract DECISION blocks
    echo "$content" | grep -A 100 '\[DECISION:' | while IFS= read -r line; do
        if [[ "$line" =~ \[DECISION:\ *([^\]]+)\] ]]; then
            local title="${BASH_REMATCH[1]}"
            local slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
            local out_file="$DECISIONS_PATH/${session_date}-${slug}.md"

            [ -f "$out_file" ] && continue

            local block=""
            local capturing=false
            while IFS= read -r bline; do
                if [[ "$bline" =~ \[DECISION:\ *${title}\] ]]; then
                    capturing=true
                    continue
                fi
                if $capturing; then
                    if [[ "$bline" =~ ^###\  ]] || [[ "$bline" =~ ^\[(LEARNING|PATTERN|DECISION): ]]; then
                        break
                    fi
                    block+="$bline"$'\n'
                fi
            done <<< "$content"

            if [ -n "$block" ]; then
                cat > "$out_file" << EOF
---
date: $session_date
title: $title
project: $project
type: decision
source: $(basename "$file")
tags: [claude-memory, decision]
---

# $title

$block
EOF
                echo "Extracted decision: $title"
            fi
        fi
    done 2>/dev/null || true
}

# Main: check ALL session files (not based on mtime - that resets on every append)
echo "[$(date)] Checking for sessions to rename and extract..."

for file in "$VAULT_PATH"/*.md; do
    [ -f "$file" ] || continue

    # Check if file has been around long enough (based on frontmatter time, not mtime)
    file_time=$(grep "^time:" "$file" 2>/dev/null | cut -d' ' -f2)
    if [ -n "$file_time" ]; then
        file_epoch=$(date -j -f "%H:%M:%S" "$file_time" "+%s" 2>/dev/null || echo 0)
        now_epoch=$(date "+%s")
        age_minutes=$(( (now_epoch - file_epoch) / 60 ))

        if [ "$age_minutes" -ge "$RENAME_AFTER_MINUTES" ]; then
            rename_session "$file"
            extract_tagged_content "$file"
        fi
    fi
done

echo "[$(date)] Done."

# Auto-close idle sessions (30 min of no new messages)
AUTO_CLOSE_MINUTES=30

for file in "$VAULT_PATH"/*.md; do
    [ -f "$file" ] || continue

    # Only process active sessions
    grep -q "status: active" "$file" 2>/dev/null || continue

    # Get the last modification time of the file
    file_mtime=$(stat -f "%m" "$file" 2>/dev/null || echo 0)
    now_epoch=$(date "+%s")
    idle_minutes=$(( (now_epoch - file_mtime) / 60 ))

    if [ "$idle_minutes" -ge "$AUTO_CLOSE_MINUTES" ]; then
        sed -i '' 's/status: active/status: completed/' "$file"
        echo "[$(date)] Auto-closed idle session: $(basename "$file") ($idle_minutes min idle)"
    fi
done

# Run compound knowledge synthesis (gated: only if new entries since last run)
SYNTH_SCRIPT="$(dirname "$0")/synthesize-knowledge.sh"
if [ -x "$SYNTH_SCRIPT" ]; then
    "$SYNTH_SCRIPT" &
fi

# Regenerate skill manifest (pure bash, fast, always safe to run)
MANIFEST_SCRIPT="$(dirname "$0")/generate-manifest.sh"
if [ -x "$MANIFEST_SCRIPT" ]; then
    "$MANIFEST_SCRIPT" >/dev/null 2>&1 &
fi

wait
