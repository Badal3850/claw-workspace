# Claw - OpenClaw Workspace

This workspace contains Claw's identity, memory, instructions, and setup scripts.
Secrets do not belong in this repo.

## Structure

```text
.
|-- SOUL.md
|-- IDENTITY.md
|-- USER.md
|-- AGENTS.md
|-- TOOLS.md
|-- HEARTBEAT.md
|-- MEMORY.md
|-- memory/
|-- scripts/
`-- README.md
```

## Deploying On A New Server

Prerequisites:

- OpenClaw installed: `curl -fsSL https://openclaw.ai/install.sh | bash`
- Node.js available through OpenClaw
- A freshly rotated `~/.openclaw/.env`

Clone or copy the workspace:

```bash
git clone https://github.com/Badal3850/claw-workspace.git ~/.openclaw/workspace
```

Restore secrets, then sync config and runtime auth:

```bash
cp /path/to/backup/.env ~/.openclaw/.env
node ~/.openclaw/workspace/scripts/fill-config.js
```

The sync script keeps provider and bot secrets out of `openclaw.json`. Provider
API keys are written to OpenClaw's runtime auth store at
`~/.openclaw/agents/main/agent/auth-profiles.json`. Telegram reads
`TELEGRAM_BOT_TOKEN` from the service environment.

Generate or refresh the gateway token:

```bash
openclaw doctor --generate-gateway-token
```

Start the gateway:

```bash
openclaw gateway start
```

Full remote bootstrap:

```bash
bash ~/.openclaw/workspace/scripts/bootstrap.sh <user> <host>
```

## Secrets Management

Keep these variables in `~/.openclaw/.env`:

| Variable | Purpose |
| --- | --- |
| `OPENROUTER_API_KEY` | OpenRouter model access |
| `GROQ_API_KEY` | Groq model access |
| `GEMINI_API_KEY` | Gemini chat and memory embeddings |
| `TELEGRAM_BOT_TOKEN` | Telegram BotFather token |
| `DISCORD_BOT_TOKEN` | Optional; Discord is disabled by default |

Important:

- Rotate every exposed value in the provider consoles before treating the setup as secure.
- Do not store backup provider accounts for quota evasion.
- Do not commit `.env`, `openclaw.json`, backups, or runtime auth files.
- Use `workspace/scripts/repair-secrets.js` after replacing keys in `.env` to resync auth without printing secrets.

## Agent Defaults

- Primary model: Gemini 2.5 Flash
- Fallbacks: Gemini 2.0 Flash, OpenRouter DeepSeek V4 Flash
- Groq: configured as a direct provider, but not in the default fallback chain because the current free-tier TPM limit rejects OpenClaw's smallest request envelope
- Heartbeat: every 30 minutes using Gemini 2.0 Flash
- Sub-agents: Gemini 2.0 Flash
- Memory search: Gemini `gemini-embedding-001`
- Channels: Telegram enabled; Discord retained but disabled

## Validation

```bash
openclaw config validate
openclaw models status
openclaw channels status
openclaw memory status
```

## Updating

```bash
cd ~/.openclaw/workspace
git add -A
git commit -m "Update workspace state"
git push
```

## License

Private personal agent workspace.
