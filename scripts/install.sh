#!/bin/bash
# Agentic OS — Claude Code hooks installer
# Installs user-prompt-tracker, session-finalizer, synthesize-knowledge,
# and registers the session-finalizer launchd agent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_SRC="$SCRIPT_DIR/hooks"
HOOKS_DST="$HOME/.claude/skills/obsidian-save/hooks"
LAUNCHD_DIR="$HOME/Library/LaunchAgents"
PLIST_LABEL="com.claude.session-finalizer"
PLIST_DST="$LAUNCHD_DIR/$PLIST_LABEL.plist"
LOG_DIR="$HOME/.claude/logs"

DEFAULT_VAULT="$HOME/Documents/agentic-os"

echo ""
echo "=== Agentic OS — Claude Code hooks installer ==="
echo ""

# Safety: refuse to clobber an existing install unless --force
FORCE=0
for arg in "$@"; do [ "$arg" = "--force" ] && FORCE=1; done
if [ "$FORCE" -eq 0 ] && [ -d "$HOME/.claude/skills/obsidian-save/hooks" ]; then
    EXISTING=$(grep -l "VAULT_PATH\|AGENTIC_OS_VAULT" "$HOME/.claude/skills/obsidian-save/hooks/"*.sh 2>/dev/null | head -1)
    if [ -n "$EXISTING" ]; then
        echo "⚠  Existing install detected at $HOME/.claude/skills/obsidian-save/hooks/"
        echo "   Re-run with --force to overwrite (this will replace your hook scripts"
        echo "   and launchd plist). Your vault content will NOT be touched."
        exit 1
    fi
fi

# Vault location
read -rp "Vault location [$DEFAULT_VAULT]: " VAULT
VAULT="${VAULT:-$DEFAULT_VAULT}"
VAULT="${VAULT/#\~/$HOME}"

echo ""
echo "Will install:"
echo "  - Hook scripts  -> $HOOKS_DST"
echo "  - launchd plist -> $PLIST_DST"
echo "  - Vault folders -> $VAULT"
echo "  - Log dir       -> $LOG_DIR"
echo ""
read -rp "Continue? [y/N]: " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

# Create vault structure
echo ""
echo "→ Creating vault structure at $VAULT"
mkdir -p "$VAULT/00_System"/{identity,brand-context,manifest,aq-context,sessions}
mkdir -p "$VAULT/00_System/knowledge"/{learnings,patterns,decisions}

# Install hook scripts
echo "→ Installing hook scripts to $HOOKS_DST"
mkdir -p "$HOOKS_DST"
cp "$HOOKS_SRC"/*.sh "$HOOKS_DST/"
chmod +x "$HOOKS_DST"/*.sh

# Log dir
mkdir -p "$LOG_DIR"

# Write launchd plist with absolute paths
echo "→ Writing launchd plist"
mkdir -p "$LAUNCHD_DIR"
cat > "$PLIST_DST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$HOOKS_DST/session-finalizer.sh</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>AGENTIC_OS_VAULT</key>
        <string>$VAULT</string>
        <key>PATH</key>
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
    </dict>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/session-finalizer.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/session-finalizer.log</string>
</dict>
</plist>
PLIST

# Load launchd agent
echo "→ Loading launchd agent"
launchctl unload "$PLIST_DST" 2>/dev/null || true
launchctl load "$PLIST_DST"

# Persist vault env var so interactive hooks and shells find it
SHELL_RC="$HOME/.zshrc"
[ -f "$HOME/.bashrc" ] && [ ! -f "$SHELL_RC" ] && SHELL_RC="$HOME/.bashrc"
if ! grep -q "AGENTIC_OS_VAULT" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Agentic OS vault location" >> "$SHELL_RC"
    echo "export AGENTIC_OS_VAULT=\"$VAULT\"" >> "$SHELL_RC"
    echo "→ Appended AGENTIC_OS_VAULT to $SHELL_RC"
fi

echo ""
echo "✓ Done."
echo ""
echo "Next steps:"
echo "  1. Register the UserPromptSubmit hook in ~/.claude/settings.json:"
echo ""
echo "       \"hooks\": {"
echo "         \"UserPromptSubmit\": ["
echo "           { \"matcher\": \"*\","
echo "             \"hooks\": [ { \"type\": \"command\","
echo "                           \"command\": \"$HOOKS_DST/user-prompt-tracker.sh\" } ] }"
echo "         ]"
echo "       }"
echo ""
echo "  2. Open a new shell (to pick up AGENTIC_OS_VAULT) or run:"
echo "       export AGENTIC_OS_VAULT=\"$VAULT\""
echo ""
echo "  3. Tail the log to verify:"
echo "       tail -f $LOG_DIR/session-finalizer.log"
echo ""
