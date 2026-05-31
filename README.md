# 🐾 Claw — OpenClaw Workspace

> Your AI agent's identity, memory, and soul — version-controlled.

This repository contains the workspace files for **Claw**, your personal OpenClaw AI agent. It stores personality (`SOUL.md`), user context (`USER.md`, `IDENTITY.md`), agent instructions (`AGENTS.md`), tool definitions (`TOOLS.md`), and long-term memory (`memory/`).

> **⚠️ Secrets are NOT stored here.** API keys, bot tokens, and credentials stay in `~/.openclaw/.env` (backed up separately — e.g., Google Drive).

---

## 📁 Structure

```
.
├── SOUL.md           # 🧠 Agent personality, core directives, behavior
├── IDENTITY.md       # 📛 Agent name, handle, defining traits
├── USER.md           # 👤 User profile, preferences, context
├── AGENTS.md         # 🤖 Sub-agent configurations & delegation rules
├── TOOLS.md          # 🔧 Available tools and usage guidelines
├── HEARTBEAT.md      # 💓 Periodic heartbeat task log
├── MEMORY.md          # 📖 Index of long-term memory files
├── memory/           # 💾 Individual memory files (facts, feedback, references)
├── scripts/          # 🛠 Deployment & bootstrap utilities
└── README.md         # ← You are here
```

### Key Files

| File | Purpose |
|------|---------|
| `SOUL.md` | The agent's core personality and operating principles. Defines how Claw thinks, communicates, and behaves. |
| `IDENTITY.md` | Name, handle, and public-facing identity. |
| `USER.md` | Who you are — your preferences, communication style, and background. |
| `AGENTS.md` | Configuration for sub-agents and delegation. |
| `TOOLS.md` | What tools are available and how they should be used. |
| `HEARTBEAT.md` | Log of periodic heartbeat tasks — shows Claw staying alive and checking in. |
| `MEMORY.md` | Index of all stored memory files, linking to individual facts and feedback. |
| `memory/` | Individual `.md` files storing facts, feedback, project notes, and references. Each file has frontmatter with name, description, and type tags. |

---

## 🚀 Deploying on a New Server

When you want to run Claw on a new machine (e.g., Oracle Cloud, VPS):

### Prerequisites

- OpenClaw installed (`curl -fsSL https://openclaw.ai/install.sh | bash`)
- Node.js (comes with OpenClaw)
- Your `.env` file with API keys (backed up separately)

### Step 1: Clone workspace

```bash
git clone https://github.com/Badal3850/claw-workspace.git ~/.openclaw/workspace
```

### Step 2: Restore config from `.env`

```bash
# Copy your .env into place (from GDrive or other backup)
cp /path/to/backup/.env ~/.openclaw/.env

# Fill secrets into openclaw.json
node ~/.openclaw/workspace/scripts/fill-config.js
```

This reads `~/.openclaw/.env` and injects all API keys (OpenRouter, Gemini, Groq, Discord, Telegram) into `~/.openclaw/openclaw.json`.

### Step 3: Generate gateway token

```bash
openclaw doctor --generate-gateway-token
```

### Step 4: Start the gateway

```bash
openclaw gateway start
```

### Full automation

For a fully automated deploy (workspace + secrets + config):

```bash
bash ~/.openclaw/workspace/scripts/bootstrap.sh <user> <host>
```

See [`scripts/bootstrap.sh`](scripts/bootstrap.sh) for details.

---

## 🔐 Secrets Management

| What | Where | Backup Method |
|------|-------|---------------|
| `openclaw.json` (with keys) | `~/.openclaw/openclaw.json` | Generated from `.env` via `scripts/fill-config.js` |
| `.env` (raw keys) | `~/.openclaw/.env` | **Google Drive** (manual backup) |
| Workspace (no secrets) | GitHub `claw-workspace` | Auto-pushed via git |

**Never commit `.env` or `openclaw.json`** — the `.gitignore` is configured to block these.

### What gets filled from `.env`

| `.env` Variable | Config Path |
|----------------|-------------|
| `OPENROUTER_API_KEY` | `env.OPENROUTER_API_KEY` |
| `OPENROUTER_API_KEY_2` | `env.OPENROUTER_API_KEY_2` |
| `OPENROUTER_API_KEY_3` | `env.OPENROUTER_API_KEY_3` |
| `GROQ_API_KEY` | `env.GROQ_API_KEY` |
| `GEMINI_API_KEY` | `env.GEMINI_API_KEY` |
| `GEMINI_API_KEY_2` | `env.GEMINI_API_KEY_2` |
| `GEMINI_API_KEY_3` | `env.GEMINI_API_KEY_3` |
| `DISCORD_BOT_TOKEN` | `channels.discord.token` |
| `DISCORD_BOT_TOKEN` | `channels.telegram.botToken` (same token in your setup) |

---

## 🧠 Memory System

The `memory/` directory stores persistent facts about you, your projects, and past interactions. Each memory is a standalone `.md` file with YAML frontmatter:

```markdown
---
name: user-shell-preference
description: Default shell and terminal setup
metadata:
  type: user
---

Uses bash on Windows via Git Bash as the primary shell.

**Why:** Native Windows experience with Unix tooling.
**How to apply:** Default to bash commands, use forward slashes in paths.
```

Memories are indexed in `MEMORY.md` with one-line links:

```markdown
- [Shell Preference](memory/user-shell-preference.md) — bash on Windows via Git Bash
```

### Types of Memory

- **`user`** — Who you are, preferences, expertise
- **`feedback`** — Corrections and confirmed approaches from you
- **`project`** — Active projects, goals, constraints
- **`reference`** — External links, docs, resources

---

## 🤖 Agent Identity

Claw is configured with:

- **Primary model:** Gemini 2.5 Flash (free tier)
- **Fallbacks:** Gemini 2.0 Flash → DeepSeek V4 Flash (via OpenRouter)
- **Heartbeat:** Every 30 minutes (uses Gemini 2.0 Flash)
- **Sub-agents:** Gemini 2.0 Flash
- **Memory search:** Gemini text-embedding-004

---

## 🔄 Updating

```bash
cd ~/.openclaw/workspace
git add -A
git commit -m "Update workspace state"
git push
```

---

## 📝 License

Private — personal agent workspace.