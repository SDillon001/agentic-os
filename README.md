# Agentic OS

**A self-maintaining operating system for your AI-powered workflow — connecting Claude Code + Amazon Quick into one coordinated brain.**

![Status](https://img.shields.io/badge/Status-Operational-brightgreen) ![License](https://img.shields.io/badge/License-MIT-blue)

---

## What is this?

Most people use AI tools one task at a time — a chatbot for writing, a coding agent for prototyping, a separate tool for research. The Agentic OS connects them into a **unified system** where Amazon Quick orchestrates across Claude Code, Slack, Email, Asana, and your local knowledge vault.

**The result:** Both agents share one evolving brain. Claude Code knows what happened in yesterday's Slack conversations. Amazon Quick knows what you built in code. Insights from every session compound automatically. A daily morning brief synthesizes action items from across all your tools. The system maintains itself.

## Architecture

```
┌──────────────────────────────────────────────────────┐
│  AMAZON QUICK (Orchestration Layer)                   │
│  Knowledge Graph · long-term memory · scheduled agents│
├──────────────────────────────────────────────────────┤
│  COMPOUND KNOWLEDGE (Learning & Memory Bridge)        │
│  [LEARNING] [PATTERN] [DECISION] → auto-synthesis     │
├──────────────────────────────────────────────────────┤
│  SELF-MAINTENANCE (Heartbeat + Wrap-up + Manifest)    │
│  Session lifecycle · skill registry · auto-close      │
├──────────────────────────────────────────────────────┤
│  SHARED CONTEXT (Vault / Local Folder)                │
│  Identity · brand context · project knowledge         │
├──────────────────────────────────────────────────────┤
│  CLAUDE CODE + OBSIDIAN + SLACK + EMAIL + ASANA       │
└──────────────────────────────────────────────────────┘
```

## Key Features

### 🧠 Compound Knowledge
Every Claude Code session generates tagged insights (`[LEARNING]`, `[PATTERN]`, `[DECISION]`) that are automatically extracted, synthesized by an LLM into themed knowledge, and made available to both Claude Code and Amazon Quick. Knowledge compounds over time — nothing is pruned or forgotten.

### 🌅 Morning Brief
A daily scheduled agent scans Slack, email, Asana, and your calendar, then delivers a prioritized briefing via **Slack DM + email + vault file**:
- ⚡ **Action items** synthesized and prioritized from all sources
- 📅 Today's calendar with conflict detection
- 💬 Slack highlights (full-scan + mention-only channels)
- 📧 Email flags (manager messages, meeting invites, deadlines)
- ✅ Asana tasks (due this week, overdue, completed yesterday)
- 💻 Yesterday's Claude Code sessions
- 🔧 Skill manifest changes

### 🔄 Self-Maintenance
- **Heartbeat** — On every CC session start, loads your preferences + compound knowledge + skill registry
- **Auto-close** — Idle sessions (30 min) automatically marked as completed
- **Skill Manifest** — Auto-generated routing table for all CC skills with overlap detection
- **Wrap-up** — `/wrap-up` command for clean session closure: list deliverables → persist work → summary → manifest regen

### 📂 Shared Context
Both agents read and write to a single vault folder (`00_System/`):
- `identity/` — Agent personality (`soul.md`) + user preferences (`user.md`)
- `brand-context/` — Design system, brand assets, voice & tone (pointer files)
- `knowledge/` — Compound knowledge + individual learnings/patterns/decisions
- `aq-context/` — Morning brief + KG-synced people/decisions/project context
- `sessions/` — Raw CC session logs
- `manifest/` — Skill registry

## Folder Structure

```
00_System/
├── KNOWLEDGE_SYSTEM.md
├── identity/
│   ├── soul.md
│   └── user.md
├── brand-context/
│   ├── design-system.md
│   ├── brand-assets.md
│   ├── voice-and-tone.md
│   └── core-skill/          (your domain reference docs)
├── manifest/
├── aq-context/
│   ├── morning-brief.md
│   ├── people-context.md
│   ├── recent-decisions.md
│   └── project-status.md
├── knowledge/
│   ├── COMPOUND_KNOWLEDGE.md
│   ├── learnings/
│   ├── patterns/
│   └── decisions/
└── sessions/
```

## Shell Scripts & Hooks

| Script | Trigger | Purpose |
|--------|---------|---------|
| `user-prompt-tracker.sh` | CC `UserPromptSubmit` hook | Creates/appends session files |
| `session-finalizer.sh` | launchd (every 5 min) | Renames, extracts tags, auto-closes idle sessions, triggers synthesis + manifest |
| `synthesize-knowledge.sh` | Called by finalizer | LLM-powered compound synthesis via `claude -p` |
| `generate-manifest.sh` | Called by finalizer | Scans skills, writes SKILL_MANIFEST.md, detects overlaps |

## Amazon Quick Agents

| Agent | Schedule | Purpose |
|-------|----------|---------|
| `agentic-os-context-sync` | Daily 6 AM | Morning brief: Slack + email + Asana + calendar + CC sessions → Slack DM + email + vault |

## Getting Started

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for step-by-step instructions to build your own Agentic OS.

**Quick version:**
1. Create the `00_System/` folder structure
2. Write `soul.md` and `user.md` for your role
3. Set up the session-finalizer launchd job
4. Add the heartbeat to your `CLAUDE.md`
5. Create the morning brief agent in Amazon Quick
6. Start tagging `[LEARNING]`, `[PATTERN]`, `[DECISION]` in your CC sessions

## Customization

The system is designed to be role-agnostic:
- **UX Designers** — Cloudscape/Figma integration, research synthesis, journey maps
- **Engineers** — Code patterns, deployment learnings, architecture decisions
- **PMs** — Meeting follow-ups, stakeholder context, project status tracking
- **Researchers** — Interview synthesis, finding patterns, decision documentation

Customize `soul.md` for your domain, configure Slack channels for your projects, and the system adapts.

## Built By

Steve Dillon ([@dsdillon](https://github.com/dsdillon))

Built over two sessions with Claude Code + Amazon Quick, April 28-29, 2026.

## License

MIT — see [LICENSE](LICENSE).

## Trademarks

Amazon Quick, AWS, and related marks are trademarks of Amazon.com, Inc. or its affiliates. Claude and Claude Code are trademarks of Anthropic, PBC. This project is an independent, community-built integration and is not affiliated with, endorsed by, or sponsored by Amazon or Anthropic.
