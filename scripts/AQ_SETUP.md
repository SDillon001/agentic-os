# Agentic OS Setup — Instructions for Amazon Quick

> **For Amazon Quick Suite Desktop:** read this file, then walk the user
> through the setup step by step. Ask for confirmation before each step.
> Do not assume defaults the user has not given you.

Reference guide: <https://github.com/dsdillon/agentic-os>

## Step 1 — Vault location
Ask where to create the vault (default: `~/Documents/agentic-os/`).
Use this same path for every file you write below.

## Step 2 — Folder structure
Create this tree inside the vault:

```
00_System/
  identity/
  brand-context/
  manifest/
  aq-context/
  knowledge/learnings/
  knowledge/patterns/
  knowledge/decisions/
  sessions/
```

## Step 3 — Identity files
Ask the user:

- Their role and team
- Their top 2–3 active projects
- Their design system (e.g., Material, Cloudscape, custom, none)
- Their preferred Slack channels to monitor
- Their communication style preferences

Then write:

- `00_System/identity/soul.md` — agent personality + behavioral rules
- `00_System/identity/user.md` — user preferences + project context
- `00_System/brand-context/design-system.md` — pointer to design system
- `00_System/brand-context/voice-and-tone.md` — writing guidelines

## Step 4 — Connections
Tell the user to open **Settings → Capabilities → Connections** and
confirm once they have connected:

- Slack
- Outlook (email + calendar)
- Asana
- Local folder pointing at the vault

Do **not** attempt to click the settings UI yourself — these are
user-initiated in AQ.

## Step 5 — Morning Brief agent
Create a scheduled agent named **Morning Brief** that:

- Runs daily at 6 AM the user's local timezone (convert to UTC for `schedule_time`)
- Scans last 24h of Slack (channels the user selected)
- Scans last 24h of email inbox
- Reads Asana tasks (open, overdue, completed yesterday)
- Reads today's calendar
- Reads yesterday's Claude Code session summaries from `00_System/sessions/`
- Synthesizes prioritized action items at the top

Delivers via: Slack DM, email, AND writes to
`00_System/aq-context/morning-brief.md`.

Also have it write:

- `00_System/aq-context/people-context.md`
- `00_System/aq-context/recent-decisions.md`
- `00_System/aq-context/project-status.md`

## Step 6 — Claude Code hooks (already included)
The Claude Code hooks live in the same .zip as this file. **Do not
generate them yourself.** Tell the user to run:

```bash
cd scripts
chmod +x install.sh
./install.sh
```

Then remind the user to:

1. Register the `UserPromptSubmit` hook in `~/.claude/settings.json`
   (installer prints the exact snippet)
2. Append the heartbeat snippet to `~/.claude/CLAUDE.md` so Claude Code
   reads vault context on session start:

   ```markdown
   # Session Start (Heartbeat)
   On first message of a new session, read these files for context:
   1. `cat <VAULT>/00_System/identity/user.md`
   2. `cat <VAULT>/00_System/knowledge/COMPOUND_KNOWLEDGE.md`
   3. `cat ~/.claude/SKILL_MANIFEST.md`
   Do this silently — don't announce you're reading them.
   ```

## Confirmation rules
- Confirm before creating each folder
- Confirm before writing each file (show contents first)
- Confirm before creating the scheduled agent
- At the end, summarize everything created and next steps

Ready — ask the user about the vault location first.
