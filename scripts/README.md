# Agentic OS — Claude Code hooks

This .zip installs the Claude Code side of the Agentic OS — the session
tracker, finalizer, knowledge synthesizer, and the launchd agent that runs
every 5 minutes to extract learnings and close idle sessions.

See the full guide: <https://github.com/dsdillon/agentic-os>

## What's inside

```
scripts/
├── install.sh                  ← interactive installer (Claude Code side)
├── AQ_SETUP.md                 ← instructions for Amazon Quick to follow
├── README.md                   ← you are here
└── hooks/
    ├── user-prompt-tracker.sh  ← UserPromptSubmit hook
    ├── session-tracker.sh      ← (legacy, kept for reference)
    ├── session-finalizer.sh    ← launchd every 5 min
    ├── synthesize-knowledge.sh ← rebuilds COMPOUND_KNOWLEDGE.md
    └── generate-manifest.sh    ← rebuilds SKILL_MANIFEST.md
```

## Install (two sides)

### Claude Code side

```bash
chmod +x install.sh
./install.sh
```

### Amazon Quick side

Open Amazon Quick Suite Desktop and paste:

```
Read AQ_SETUP.md from the agentic-os.zip and walk me
through setup. Path: /absolute/path/to/scripts/AQ_SETUP.md
```

(Or just drag `AQ_SETUP.md` into the AQ chat.)

The installer will:

1. Ask where to put your vault (default `~/Documents/agentic-os/`)
2. Create the `00_System/` folder structure
3. Copy hook scripts to `~/.claude/skills/obsidian-save/hooks/`
4. Write and load `~/Library/LaunchAgents/com.claude.session-finalizer.plist`
5. Append `export AGENTIC_OS_VAULT=...` to your shell rc

Then follow the printed instructions to register the `UserPromptSubmit`
hook in `~/.claude/settings.json`.

## Customizing the vault path

All scripts read `$AGENTIC_OS_VAULT`. Change it in your shell rc (or the
launchd plist) to move your vault without editing the scripts.

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.claude.session-finalizer.plist
rm ~/Library/LaunchAgents/com.claude.session-finalizer.plist
rm -rf ~/.claude/skills/obsidian-save/hooks
```

The vault folder is left intact.
