# Agentic OS Blueprint

**Steve Dillon ([@dsdillon](https://github.com/dsdillon))**
**Created:** 2026-04-28
**Status:** ✅ OPERATIONAL (Layers 1-3 complete, Layer 4 future)
**Last updated:** 2026-04-29

---

## Overview

An **Agentic Operating System** that unifies Claude Code and Amazon Quick into a single coordinated system — sharing context, memory, and skill awareness across both platforms via the Obsidian vault as the common filesystem. Amazon Quick serves as the **orchestration layer** on top, with Claude Code, the Obsidian vault, and external tools as the infrastructure underneath.

### Design Principles

1. **CLAUDE.md stays thin** — behavioral rules only, never a skill registry
2. **Git-agnostic** — works with any VCS, any deploy target, OR no VCS at all
3. **Obsidian vault is the bus** — both agents read/write to `<your-vault>/00_System/`
4. **Lazy loading** — full skill instructions loaded on-demand, not upfront
5. **Compound knowledge** — learnings build cumulatively into themed knowledge, nothing pruned
6. **Extend existing infrastructure** — session-finalizer.sh and tag-based extraction remain the backbone

---

## Architecture: 4 Layers

```
┌─────────────────────────────────────────────────────────────┐
│  AMAZON QUICK (Orchestration Layer)                          │
│  KG, long-term memory, scheduled agents, background tasks    │
├─────────────────────────────────────────────────────────────┤
│  LAYER 1: Shared Context (Obsidian Vault — 00_System/)       │
│  Identity, brand context, core-skill docs, manifests         │
├─────────────────────────────────────────────────────────────┤
│  LAYER 2: Learning & Memory Bridge                           │
│  Compound knowledge synthesis (55 entries, 11 themes)        │
│  CC learnings ↔ AQ memory ↔ Knowledge Graph                 │
├─────────────────────────────────────────────────────────────┤
│  LAYER 3: Self-Maintenance                                   │
│  Heartbeat (session start) + Wrap-up (session end)           │
│  SKILL_MANIFEST.md (17 skills, overlap detection)            │
├─────────────────────────────────────────────────────────────┤
│  LAYER 4: Skill Chaining / Workflows (Future)                │
│  Research → Design → Prototype → Deploy pipelines            │
├─────────────────────────────────────────────────────────────┤
│  INFRASTRUCTURE: Claude Code (17 skills) + Obsidian Vault    │
│  + Git + Deploy Target + Figma MCP + Cloud Storage           │
└─────────────────────────────────────────────────────────────┘
```

---

## Consolidated Folder Structure (as of 2026-04-29)

All Agentic OS files live in one place:

```
<your-vault>/00_System/
├── KNOWLEDGE_SYSTEM.md              ← Docs for the tag extraction system
├── identity/
│   ├── soul.md                      ← Agent personality, priorities, guardrails
│   └── user.md                      ← Your preferences, project context, feedback history
├── brand-context/
│   ├── design-system.md             ← Pointer → your design system skill/docs
│   ├── brand-assets.md              ← Pointer → your brand asset location
│   ├── voice-and-tone.md            ← Pointer → your voice & writing guidelines
│   └── core-skill/                  ← Your domain reference docs (optional)
├── manifest/
│   └── (SKILL_MANIFEST.md also at ~/.claude/SKILL_MANIFEST.md)
├── aq-context/                      ← Written daily by AQ context sync agent (6 AM)
│   ├── people-context.md            ← Collaborators by project
│   ├── recent-decisions.md          ← Decisions from Slack/email/meetings (7 days)
│   └── project-status.md            ← Active project snapshot
├── knowledge/
│   ├── COMPOUND_KNOWLEDGE.md        ← 55 entries, 11 themes (auto-synthesized)
│   ├── learnings/                   ← 32 extracted [LEARNING] files
│   ├── patterns/                    ← 12 extracted [PATTERN] files
│   └── decisions/                   ← 11 extracted [DECISION] files
└── sessions/                        ← 160 CC session logs
```

---

## Layer 1: Shared Context ✅

### What's in place

| File | Purpose |
|------|---------|
| `identity/soul.md` | Agent identity — communication style, priorities, guardrails |
| `identity/user.md` | User preferences — working style, project context, tool preferences, feedback history |
| `brand-context/design-system.md` | Pointer to your design system skill / docs |
| `brand-context/brand-assets.md` | Pointer to your brand asset location (e.g., cloud storage) |
| `brand-context/voice-and-tone.md` | Pointer to your voice & writing guidelines |
| `brand-context/core-skill/` | Optional: scraped pages from your design system |

Both Claude Code and Amazon Quick can read all files in `00_System/`.

---

## Layer 2: Learning & Memory Bridge ✅

### Compound Knowledge Pipeline

```
CC session: user/agent tags [LEARNING], [PATTERN], [DECISION]
    │
    ▼ (every 5 min via launchd)
session-finalizer.sh
    ├── Renames session files based on key term extraction
    ├── Extracts tagged blocks → individual files in knowledge/learnings|patterns|decisions/
    │
    ▼ (immediately after, backgrounded)
synthesize-knowledge.sh
    ├── Checks: any new source files since last synthesis?
    ├── If yes → reads ALL knowledge files + existing COMPOUND_KNOWLEDGE.md
    ├── Runs claude -p (headless) to fold new entries into themed knowledge
    └── Overwrites COMPOUND_KNOWLEDGE.md (themes preserved across runs)
    │
    ▼ (also backgrounded)
generate-manifest.sh
    └── Re-scans ~/.claude/skills/, regenerates SKILL_MANIFEST.md
```

### Current State

| Metric | Value |
|--------|-------|
| Total knowledge sources | 55 (32 learnings + 12 patterns + 11 decisions) |
| Compound themes | 11 |
| Sessions captured | 160 |
| Retroactive extractions | 45 (from 153 previously-untagged sessions) |

### Key themes in COMPOUND_KNOWLEDGE.md

1. Session & Memory Management (5 entries)
2. Design System Prototyping (7 entries)
3. Deployment & CSP (9 entries)
4. Validation & Verification (5 entries)
5. Working Directory & Multi-Repo Safety (2 entries)
6. AWS Infrastructure & Deployment (6 entries)
7. Figma & Design Tools (4 entries)
8. LLM & API Patterns (4 entries)
9. Obsidian Formatting (1 entry)
10. CLAUDE.md & Permission Patterns (5 entries)
11. File Sync & External Systems (3+ entries)

### AQ → CC Direction: Daily Context Sync

**Agent:** [agentic-os-context-sync](agent://agentic-os-context-sync)
**Schedule:** Daily at 6:00 AM PDT
**Model:** fast
**Writes to:** `00_System/aq-context/`

Queries the Knowledge Graph for people, decisions, and project status — writes 3 markdown files that CC reads on session start via the heartbeat.

---

## Layer 3: Self-Maintenance ✅

### Heartbeat (Session Start)

Added to top of `~/.claude/CLAUDE.md`:

```
# Session Start (Heartbeat)
On first message of a new session, read these files for context:
1. cat $AGENTIC_OS_VAULT/00_System/identity/user.md
2. cat $AGENTIC_OS_VAULT/00_System/knowledge/COMPOUND_KNOWLEDGE.md
3. cat ~/.claude/SKILL_MANIFEST.md
```

### SKILL_MANIFEST.md

**Generator:** `~/.claude/skills/obsidian-save/hooks/generate-manifest.sh`
**Location:** `~/.claude/SKILL_MANIFEST.md`
**Skills registered:** 17
**Overlap detection:** Flags skill pairs sharing 3+ keywords

Current overlaps worth reviewing:
- Two separate document-sync skills (10 shared keywords — near-duplicates, consider merging)
- `deploy` ↔ `sync-and-deploy` (5 shared — different scopes, descriptions could be tightened)

### Wrap-Up Skill (Session End)

**Manual trigger:** `/wrap-up`, "close session", "done for now"
**Location:** `~/.claude/skills/wrap-up/SKILL.md`

| Step | What it does |
|------|-------------|
| 1 | List deliverables (git status or recently modified files) |
| 2 | Persist work — git-agnostic: commit if .git/, deploy if applicable, else confirm saved |
| 3 | Write 3-5 line session summary |
| 4 | Run generate-manifest.sh to sync skill registry |

> **No feedback questions.** The [LEARNING]/[PATTERN]/[DECISION] inline tags capture insights during the session. The compound knowledge pipeline synthesizes them automatically. Asking again at the end is unnecessary friction.

### Auto-Close (Inactivity Detection)

**Trigger:** session-finalizer.sh detects no new messages for **30 minutes**
**Action:** Flips `status: active → completed` in the session file frontmatter. Runs generate-manifest.sh. Does NOT close Claude Code, does NOT write summaries, does NOT require an LLM call. Pure shell, runs in the existing 5-min launchd cycle.

This catches accidental CC closes and forgotten sessions — ensures every session gets marked as completed even if you don't `/wrap-up`.

---

## Layer 4: Skill Chaining (Future) ⏳

> **Not built yet** — Layers 1-3 provide the foundation.

Planned workflow chains:

| Pipeline | Steps | Tools |
|----------|-------|-------|
| **Research → Report** | AQ deep analysis → CC generates Excalidraw diagrams → AQ creates DOCX | AQ + CC |
| **Design → Prototype** | Figma MCP (CC) → component build (CC) → deploy (CC) → AQ logs | CC + AQ |
| **Meeting → Actions** | AQ reads Outlook meeting summary → extracts action items → creates Asana tasks | AQ |

---

## Shell Scripts & Hooks

| Script | Location | Trigger | What it does |
|--------|----------|---------|-------------|
| `user-prompt-tracker.sh` | obsidian-save/hooks/ | `UserPromptSubmit` hook (every user message) | Creates/appends to session files |
| `session-finalizer.sh` | obsidian-save/hooks/ | launchd (every 5 min) | Renames sessions, extracts tags, triggers synthesis + manifest |
| `synthesize-knowledge.sh` | obsidian-save/hooks/ | Called by session-finalizer (backgrounded) | LLM-powered compound synthesis via `claude -p` |
| `generate-manifest.sh` | obsidian-save/hooks/ | Called by session-finalizer (backgrounded) | Scans skills/, writes SKILL_MANIFEST.md |
| *(auto-close logic)* | Inside session-finalizer.sh | Every 5 min (checks idle time) | Marks sessions as completed after 30 min of inactivity |

**launchd plist:** `~/Library/LaunchAgents/com.claude.session-finalizer.plist`
**Logs:** `~/.claude/logs/session-finalizer.log`, `~/.claude/logs/synthesize-knowledge.log`

---

## Key Constraints & Decisions Log

| Decision | Rationale |
|----------|-----------|
| Obsidian vault as shared bus | Both CC and AQ already have read/write access; PARA structure in place |
| CLAUDE.md stays thin | Bloated root config = slower responses + context waste |
| Tiered manifest (CLAUDE.md → SKILL_MANIFEST.md → individual SKILL.md) | Mirrors AQ's own available_skills → use_skill() pattern |
| Git-agnostic wrap-up | Not all projects use git; some are deploy-only, some are doc-only |
| VCS-agnostic | Wrap-up adapts per project regardless of hosting (GitHub, GitLab, internal, etc.) |
| Pointer files not copies | Brand context points to sources, doesn't duplicate 4.1GB of assets |
| Extend session-finalizer | Already runs via launchd every 5 min; don't add another daemon |
| Hook + finalizer for heartbeat | Hook on start (immediate), finalizer on end (cleanup) |
| Daily AQ→vault sync | Project context changes fast; daily keeps CC sessions current |
| Compound knowledge, not rolling window | Learnings build cumulatively into themed knowledge — nothing pruned. session-finalizer handles extraction; LLM synthesis handles compounding. |
| Consolidate to 00_System/ | Single location for all Agentic OS files instead of split across 03_Resources/Claude/ |
| Deprecated skills deleted | Legacy design-system skills removed; redirected to a single unified design-system skill |
