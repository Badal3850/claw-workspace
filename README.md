---
title: My Claw Agent
emoji: 🤖
colorFrom: indigo
colorTo: pink
sdk: docker
pinned: false
---
***

# 🧠 Claw Workspace: Your Personal AI "Digital Brain"
> **A private, repo-native OpenClaw agent template with auditable memory, free-first model routing, and safe sync defaults.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Cost Policy: Free First](https://img.shields.io/badge/Cost%20Policy-Free%20First-brightgreen)](#-model-fallback--cost-policy)
[![Engine: OpenClaw](https://img.shields.io/badge/Engine-OpenClaw-blue)](https://docs.openclaw.ai/)

**Claw** is an autonomous agent workspace that lives inside your GitHub repository. Unlike typical AI bots, Claw has a **long-term memory**, a **defined personality**, and an explicit **free-first / paid-last** model policy. It uses GitHub as its auditable hard drive and OpenClaw as its runtime.

---

## ⚡ Deployment Paths

Choose the mode that matches where you want Claw to run.

### 1. GitHub Actions — scheduled memory cycle

Best for hourly, bounded check-ins that can update memory and then exit.

1. Fork this repository.
2. Keep the default branch as `master`, or set `CLAW_BRANCH` everywhere if you rename it.
3. Add at least one free model secret:
   - `GEMINI_API_KEY` or `GEMINI_API_KEY_FREE_1`
   - optionally `OPENROUTER_API_KEY` or `OPENROUTER_API_KEY_FREE_1`
4. Add `CLAW_PAT` only if the default `GITHUB_TOKEN` cannot push to your branch.
5. Enable Actions.
6. Run **Claw Autonomous Cycle** manually once from the Actions tab and verify that it exits within the job timeout.

The scheduled workflow calls `scripts/agent-cycle.sh`. It initializes OpenClaw config, validates model/auth setup, runs one agent turn, stages only allowlisted memory paths, commits if needed, pushes, and exits.

### 2. Hugging Face Space / container — long-running gateway

Best for a persistent OpenClaw gateway process.

1. Add runtime secrets in the hosting platform, such as `GEMINI_API_KEY` and optionally `OPENROUTER_API_KEY`.
2. Build the Docker image.
3. Start the container; `scripts/run.sh` initializes OpenClaw config and starts the gateway on port `7860` by default.

This mode does **not** commit files. It also does not write API keys into `openclaw.json`.

### 3. Remote machine bootstrap

Best when you want Claw installed on a VPS or personal machine.

```bash
bash scripts/bootstrap.sh <remote-user> <remote-host> [openclaw-home]
```

The bootstrap script copies workspace files, copies your remote `.env`, and uses the shared config initializer to put provider secrets in OpenClaw runtime auth storage instead of plain config.

---

## 🧭 Configuration Architecture

There is one source of truth for runtime configuration:

```bash
config/model-policy.json          # Free-first / paid-last provider and model policy
scripts/init-openclaw-config.js   # Generates active OpenClaw config + runtime auth
scripts/fill-config.js            # Backward-compatible wrapper
scripts/agent-cycle.sh            # Bounded GitHub Actions cycle
scripts/run.sh                    # Long-running gateway/container entry point
```

Generated runtime files are local to OpenClaw state and are not committed:

```bash
~/.openclaw/openclaw.json
~/.openclaw/.env
~/.openclaw/agents/main/agent/auth-profiles.json
```

This follows OpenClaw's model: secrets live in runtime auth profiles, while `openclaw.json` contains model/provider metadata and routing order.

---

## 💸 Model Fallback & Cost Policy

Default policy: **free profiles first, free models first, paid fallback disabled**.

| Order | Provider | Model | Secret examples | Tier |
| --- | --- | --- | --- | --- |
| 1 | Google Gemini | `google/gemini-2.5-flash-lite` | `GEMINI_API_KEY`, `GEMINI_API_KEY_FREE_1` | Free-first |
| 2 | Google Gemini | `google/gemini-2.5-flash` | `GEMINI_API_KEY_FREE_2`, `GOOGLE_API_KEY` | Free-first |
| 3 | OpenRouter | `openrouter/openrouter/free` | `OPENROUTER_API_KEY`, `OPENROUTER_API_KEY_FREE_1` | Free router |
| 4 | OpenRouter | `openrouter/deepseek/deepseek-v4-flash:free` | `OPENROUTER_API_KEY_FREE_2` | Free model |
| Last, opt-in only | OpenRouter | `openrouter/auto` | `OPENROUTER_API_KEY_PAID` | Paid fallback |

### Multiple free keys

The initializer creates one OpenClaw auth profile per key and sets `auth.order` so free keys rotate before paid keys:

```bash
GEMINI_API_KEY=...
GEMINI_API_KEY_FREE_1=...
GEMINI_API_KEY_FREE_2=...
OPENROUTER_API_KEY=...
OPENROUTER_API_KEY_FREE_1=...
```

OpenClaw can then rotate profiles on rate limits/cooldowns before walking the model fallback chain.

### Paid fallback is opt-in

Paid profiles and paid models are ignored unless you explicitly set:

```bash
CLAW_ENABLE_PAID_FALLBACK=true
```

Then, and only then, `GEMINI_API_KEY_PAID` / `OPENROUTER_API_KEY_PAID` can be added to runtime auth profiles and paid models can appear at the end of the fallback chain.

### Groq/Grok default removed

Groq/Grok is not part of the default policy because this template's promise is free-first and predictable. You can add it later as an advanced custom provider, but the default generated config does not enable it.

---

## 🛠 The "Forever Free" Stack

This workspace leverages generous free tiers to avoid a monthly bill by default:

* **Brain:** Gemini free-tier keys and OpenRouter free models/router, in a free-first order.
* **Memory:** GitHub Markdown files, version-controlled.
* **Compute:** GitHub Actions for bounded cycles or Hugging Face Spaces for a long-running container.

---

## 📂 Anatomy of an Agent

```bash
├── 🧠 SOUL.md              # Core personality, ethics, and communication style.
├── 🆔 IDENTITY.md          # Name, handle, and specific character traits.
├── 👤 USER.md              # Your profile—Claw’s knowledge about YOU.
├── 📖 MEMORY.md            # Curated long-term memory index.
├── 📁 memory/              # Raw logs, facts, and learned data.
├── 🤖 AGENTS.md            # Operating rules for agents in this repo.
├── 💓 HEARTBEAT.md         # Time-sensitive checks and autonomous heartbeat notes.
├── config/model-policy.json
├── scripts/init-openclaw-config.js
├── scripts/run.sh
└── scripts/agent-cycle.sh
```

---

## 🔒 Privacy & Secret Safety

Claw is designed so your private data stays under your control:

* Secrets belong in GitHub/Hugging Face secrets, environment variables, or OpenClaw runtime auth storage.
* `openclaw.json`, `.env` files, `.openclaw/`, and `node_modules/` are ignored by Git.
* Scheduled sync stages only allowlisted memory files (`MEMORY.md`, `HEARTBEAT.md`, and `memory/`) instead of `git add .`.
* The CI workflow is bounded with a timeout and concurrency guard to prevent overlapping hourly runs.
* Paid fallback is disabled unless `CLAW_ENABLE_PAID_FALLBACK=true`.

---

## ✅ Verification Commands

Run these locally after setting at least one model key in your environment:

```bash
npm ci
npm run init:config
npx openclaw config validate
npx openclaw models status --check
```

For live provider checks, opt in explicitly:

```bash
CLAW_PROBE_MODELS=true npm run agent:cycle
```

---

## 🌈 Use Cases

* **Second Brain:** Feed Claw articles, notes, and goals; let it organize them into Markdown memory.
* **Autonomous Coding Notes:** Give Claw a project goal and let it draft plans, decisions, and follow-ups.
* **Personal Assistant:** Configure Claw to monitor tasks and remind you of deadlines through supported OpenClaw channels.

---

### 🤝 Credits

Built on the **[OpenClaw](https://github.com/OpenClaw)** framework.  
Template maintained by [@Badal3850](https://github.com/Badal3850)

***
