# Agentic OS Setup Guide

**How to build your own Agentic Operating System with Claude Code + Amazon Quick**
*Based on Steve Dillon's ([@dsdillon](https://github.com/dsdillon)) implementation*

---

## What This Is

An **Agentic OS** is a system where your AI tools (Claude Code and Amazon Quick) share context, memory, and skill awareness through a common knowledge base — so they work as one coordinated system rather than isolated chatbots.

**What you get:**
- 🧠 **Compound knowledge** — every session's insights accumulate and compound over time
- 🌅 **Daily morning brief** — Slack DM + email with action items, calendar, Slack highlights, Asana tasks
- 🔄 **Self-maintaining** — the system syncs its own skill registry, closes idle sessions, and regenerates itself
- 🤝 **Cross-platform context** — Claude Code knows what happened in Slack/email, Amazon Quick knows what you built in code

**Prerequisites:**
- Claude Code installed and configured
- Amazon Quick (QuickSuite Desktop) with Slack, Outlook, and Asana connected
- An Obsidian vault (or any local markdown folder structure)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│  AMAZON QUICK (Orchestration Layer)              │
│  KG, memory, scheduled agents, morning brief     │
├─────────────────────────────────────────────────┤
│  COMPOUND KNOWLEDGE (Learning & Memory Bridge)   │
│  Auto-extraction → LLM synthesis → shared brain  │
├─────────────────────────────────────────────────┤
│  SELF-MAINTENANCE (Heartbeat + Wrap-up)           │
│  Skill manifest, auto-close, session lifecycle    │
├─────────────────────────────────────────────────┤
│  SHARED CONTEXT (Your Vault / Folder)             │
│  Identity, brand context, project knowledge       │
├─────────────────────────────────────────────────┤
│  CLAUDE CODE + OBSIDIAN + EXTERNAL TOOLS          │
└─────────────────────────────────────────────────┘
```

---

## Step 1: Create the Folder Structure

Create this folder structure in your Obsidian vault (or any local folder both Claude Code and Amazon Quick can access):

```
00_System/
├── identity/
│   ├── soul.md              ← Agent personality & behavioral rules
│   └── user.md              ← Your preferences & project context
├── brand-context/
│   ├── design-system.md     ← Pointer to your design system docs
│   ├── brand-assets.md      ← Pointer to brand asset locations
│   └── voice-and-tone.md    ← Writing guidelines
├── manifest/
│   └── (SKILL_MANIFEST.md will be auto-generated here)
├── aq-context/
│   └── (morning brief + context sync files written here daily)
├── knowledge/
│   ├── learnings/           ← Extracted [LEARNING] tags
│   ├── patterns/            ← Extracted [PATTERN] tags
│   ├── decisions/           ← Extracted [DECISION] tags
│   └── COMPOUND_KNOWLEDGE.md  ← Auto-synthesized compound knowledge
├── sessions/                ← Raw CC session logs
└── KNOWLEDGE_SYSTEM.md      ← Docs for the tag extraction system
```

### Write the identity files

**soul.md** — How both agents should behave. Customize for your role:

```markdown
# Agent Identity

## Role
[Your role — e.g., "Senior UX designer for a platform team"]

## Communication Style
- [Your preference — e.g., "Direct, concise — bullet points over paragraphs"]
- Proactively tag [LEARNING], [PATTERN], [DECISION] in CC sessions
- Reference vault knowledge before giving advice

## Priorities
1. [Your top priority — e.g., "Design quality"]
2. [Second priority — e.g., "Speed"]
3. Knowledge capture (every session should leave traces)

## Guardrails
- Never delete or overwrite data without explicit confirmation
- Validate changes before declaring done
- Check if a relevant skill exists before writing code from scratch
```

**user.md** — Your preferences and project context:

```markdown
# User Preferences

## Working Style
- [How you like outputs formatted]
- [Tools you use daily]
- [Any preferences for communication]

## Project Context
- Primary projects: [list your active projects]
- Design System: [what you use]
- Deploy method: [Vercel, Netlify, internal, etc.]
- VCS: [GitHub, GitLab, internal, etc. — or "none for some projects"]

## Feedback History
(Updated automatically by the wrap-up skill)
```

### Write brand-context pointer files

These don't duplicate assets — they just tell agents where to find the source of truth:

```markdown
# design-system.md
Source: [path to your design system skill or docs]
Live docs: [URL if applicable]
Key conventions: [e.g., "Internal packages, orange buttons"]
```

---

## Step 2: Set Up the Knowledge Capture Pipeline

This is the backbone — it captures knowledge from every Claude Code session automatically.

### 2a. Session Tracker Hook

Create `~/.claude/skills/obsidian-save/hooks/user-prompt-tracker.sh` — a Claude Code `UserPromptSubmit` hook that:
- Creates a session file on first message (`YYYYMMDD-{slug}.md`)
- Appends each user message with timestamp
- Saves to `00_System/sessions/`

Register it in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/your/hooks/user-prompt-tracker.sh"
          }
        ]
      }
    ]
  }
}
```

### 2b. Session Finalizer (launchd)

Create `~/.claude/skills/obsidian-save/hooks/session-finalizer.sh` — runs every 5 minutes via launchd:

1. **Renames** sessions with generic IDs based on key term extraction
2. **Extracts** `[LEARNING]`, `[PATTERN]`, `[DECISION]` tagged blocks → individual files
3. **Auto-closes** sessions idle for 30+ minutes (flips `status: active → completed`)
4. **Triggers** compound synthesis (step 2c) and manifest generation (step 3b)

Create a launchd plist at `~/Library/LaunchAgents/com.claude.session-finalizer.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude.session-finalizer</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/path/to/hooks/session-finalizer.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/YOU/.claude/logs/session-finalizer.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOU/.claude/logs/session-finalizer.log</string>
</dict>
</plist>
```

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.claude.session-finalizer.plist
```

### 2c. Compound Knowledge Synthesis

Create `~/.claude/skills/obsidian-save/hooks/synthesize-knowledge.sh`:

- Checks if any new learnings/patterns/decisions exist since last synthesis
- If yes → runs `claude -p` (headless) to read ALL source files + existing COMPOUND_KNOWLEDGE.md
- Folds new entries into existing themes (preserves theme stability across runs)
- Writes `00_System/knowledge/COMPOUND_KNOWLEDGE.md`

**Key:** This uses an LLM call (`claude -p`) but only runs when new material exists. The prompt tells Claude to preserve existing themes and fold new entries in, so the file gets smarter over time without losing structure.

Run manually with: `synthesize-knowledge.sh --force`

### 2d. Tag your work

During Claude Code sessions, tag insights inline:

```
[LEARNING: Strict CSP blocks external WebSocket connections]
Live demos must run localhost-only — a strict Content Security Policy
rejects external WebSocket connections silently.

[PATTERN: OAuth one-click setup]
curl -X POST "$AUTH_URL" -d "grant_type=authorization_code&code=$CODE"
Reduces 5-step manual setup to one copy-paste.

[DECISION: Use Protozoa pattern for CloudShell integration]
Trade-off: More complex initial setup, but better user testing isolation.
Chosen over iframe approach because of CSP constraints.
```

The session-finalizer extracts these automatically every 5 minutes.

---

## Step 3: Self-Maintenance

### 3a. Heartbeat (CLAUDE.md)

Add this to the TOP of your `~/.claude/CLAUDE.md`:

```markdown
# Session Start (Heartbeat)
On first message of a new session, read these files for context:
1. `cat ~/path/to/00_System/identity/user.md` — preferences
2. `cat ~/path/to/00_System/knowledge/COMPOUND_KNOWLEDGE.md` — compound learnings
3. `cat ~/.claude/SKILL_MANIFEST.md` — current skill registry (if it exists)

Do this silently — don't announce you're reading them.
```

This gives Claude Code ambient context on every session start — your preferences, accumulated knowledge, and available skills.

### 3b. Skill Manifest Generator

Create `~/.claude/skills/obsidian-save/hooks/generate-manifest.sh`:

- Scans every `~/.claude/skills/*/SKILL.md` for YAML frontmatter
- Writes `~/.claude/SKILL_MANIFEST.md` with a routing table (name + description per skill)
- Detects overlapping skills (shared trigger keywords)
- Called by session-finalizer after synthesis

**Every skill needs YAML frontmatter** for the manifest to pick it up:

```yaml
---
name: my-skill
description: What this skill does. Triggers on keyword1, keyword2, keyword3.
---
```

### 3c. Wrap-Up Skill

Create `~/.claude/skills/wrap-up/SKILL.md` — triggered by `/wrap-up`, "close session", or "done for now":

1. List deliverables (git status or recently modified files)
2. Persist work (git-agnostic — commit if `.git/`, deploy if applicable, else confirm saved)
3. Write 3-5 line session summary to the active session file
4. Run generate-manifest.sh

---

## Step 4: Amazon Quick Integration

### 4a. Connect Your Tools

In Amazon Quick, go to **Settings → Capabilities → Connections** and connect:
- **Slack** — for channel scanning
- **Outlook** — for email + calendar
- **Local folders** — add your vault folder (e.g., `~/Documents/your-vault/`)

### 4b. Morning Brief Agent

Create a scheduled agent in Amazon Quick that runs daily. This is the orchestration centerpiece — it pulls from all your connected systems and writes a comprehensive morning brief.

**What it does each morning:**

1. **Scans Slack channels** (last 24 hrs) — extracts decisions, action items, design feedback
2. **Scans email inbox** (last 24 hrs) — flags meeting invites, requests needing response, deadlines
3. **Reads Asana tasks** — open tasks due this week, overdue, completed yesterday
4. **Reads today's calendar** — meetings, conflicts, OOO teammates
5. **Reads yesterday's CC sessions** — what was worked on
6. **Reads skill manifest** — any changes to the skill registry
7. **Synthesizes ⚡ Action Items** at the top — prioritized by urgency

**Delivers via:**
- Slack DM (scannable on mobile)
- Email (for reference)
- Vault file at `00_System/aq-context/morning-brief.md` (for CC to read on session start)

Configure the schedule for your timezone (the `time_of_day` setting uses UTC internally):
- 6:00 AM PDT = `13:00` UTC
- 6:00 AM PST = `14:00` UTC
- 9:00 AM EST = `14:00` UTC

### 4c. Additional Context Sync

The same agent also writes:
- `people-context.md` — collaborators by project from the Knowledge Graph
- `recent-decisions.md` — decisions from Slack/email/meetings (last 7 days)
- `project-status.md` — active project snapshot

These give Claude Code ambient awareness of your work relationships and project status.

---

## Step 5: Retroactive Knowledge Sweep (Optional)

If you already have Claude Code session history, you can extract knowledge retroactively:

1. Ask Claude Code to read all your session files
2. For each session, identify learnings/patterns/decisions that should have been tagged
3. Write them to the appropriate `knowledge/` folders
4. Run `synthesize-knowledge.sh --force` to rebuild COMPOUND_KNOWLEDGE.md

This dramatically enriches your compound knowledge from day one — a representative sweep can extract dozens of insights from a hundred-plus existing sessions.

---

## How It All Connects

```
You work in Claude Code
    ↓ (every message)
user-prompt-tracker.sh → creates/appends session file
    ↓ (every 5 min)
session-finalizer.sh
    ├── Renames sessions
    ├── Extracts [LEARNING] [PATTERN] [DECISION] tags
    ├── Auto-closes idle sessions (30 min)
    ├── Triggers synthesize-knowledge.sh → COMPOUND_KNOWLEDGE.md
    └── Triggers generate-manifest.sh → SKILL_MANIFEST.md
    
Next CC session → heartbeat reads user.md + COMPOUND_KNOWLEDGE.md + SKILL_MANIFEST.md
    
Daily at 6 AM → AQ morning brief agent
    ├── Scans Slack, email, Asana, calendar, CC sessions
    ├── Synthesizes action items
    ├── Sends Slack DM + email
    └── Writes to 00_System/aq-context/ (CC reads these too)
```

---

## Customization Tips

- **Slack channels:** Configure which channels to full-scan vs. mention-only scan
- **Soul.md:** Tailor the agent personality to your role and domain
- **Brand context:** Point to your team's design system (Material, Cloudscape, custom, etc.)
- **Skill manifest:** Every skill with frontmatter gets auto-registered
- **Morning brief timing:** Adjust the UTC schedule time for your timezone
- **Auto-close threshold:** 30 minutes is the default; adjust in session-finalizer.sh

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| COMPOUND_KNOWLEDGE.md not updating | Check `~/.claude/logs/synthesize-knowledge.log`. Run `synthesize-knowledge.sh --force` manually. |
| Morning brief not arriving | Check `get_agent_run_history` in AQ. Verify schedule_time is in UTC. |
| Session-finalizer not running | `launchctl list | grep session-finalizer`. Check the log file. |
| Slack DM not visible | Check your self-DMs in Slack — the agent sends as you. |
| Skills missing from manifest | Ensure each skill has `---` YAML frontmatter with `name:` and `description:`. |
| No tags being extracted | Claude Code needs `[LEARNING: Title]` format exactly — check KNOWLEDGE_SYSTEM.md for syntax. |
