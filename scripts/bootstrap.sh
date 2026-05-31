#!/bin/bash
# OpenClaw Bootstrap Script
# Clones workspace & fills secrets from .env into openclaw.json
#
# Usage: bash bootstrap.sh <remote-user> <remote-host> [openclaw-home]
#
# Example:
#   bash bootstrap.sh ubuntu openclaw
#   bash bootstrap.sh ubuntu 10.0.0.1 ~/openclaw

set -euo pipefail

REMOTE_USER="${1?Usage: $0 <remote-user> <remote-host> [openclaw-home]}"
REMOTE_HOST="${2?Usage: $0 <remote-user> <remote-host> [openclaw-home]}"
OPENCLAW_HOME="${3:-$HOME/.openclaw}"
WORKSPACE_DIR="$OPENCLAW_HOME/workspace"

# ─── 1. SSH into remote & install OpenClaw ───
echo "==> Installing OpenClaw on $REMOTE_USER@$REMOTE_HOST..."
ssh "$REMOTE_USER@$REMOTE_HOST" <<'SSH'
  set -e
  # Install OpenClaw
  curl -fsSL https://openclaw.ai/install.sh | bash
  source ~/.bashrc

  # Create openclaw home if missing
  mkdir -p ~/.openclaw/workspace
SSH

# ─── 2. Copy workspace files (exclude secrets) ───
echo "==> Copying workspace files..."
rsync -avz --delete \
  --exclude='.git/' \
  --exclude='*.env' \
  --exclude='*.bak' \
  --exclude='*.bak.*' \
  --exclude='.openclaw/' \
  "$WORKSPACE_DIR/" \
  "$REMOTE_USER@$REMOTE_HOST:~/.openclaw/workspace/"

# ─── 3. Copy .env ───
echo "==> Copying .env..."
scp "$OPENCLAW_HOME/.env" "$REMOTE_USER@$REMOTE_HOST:~/.openclaw/.env"

# ─── 4. Run config fill on remote ───
echo "==> Filling openclaw.json from .env..."
ssh "$REMOTE_USER@$REMOTE_HOST" bash -s <<'BOOTSTRAP'
  set -euo pipefail
  OPENCLAW_HOME="${HOME}/.openclaw"
  CONFIG="$OPENCLAW_HOME/openclaw.json"
  ENV_FILE="$OPENCLAW_HOME/.env"

  # Create default config if missing
  if [ ! -f "$CONFIG" ]; then
    echo "{}" > "$CONFIG"
  fi

  # Source .env
  set -a
  source "$ENV_FILE"
  set +a

  # Helper: set nested JSON key
  set_json() {
    local key="$1" value="$2"
    # Uses node to safely set nested keys
    node -e "
      const fs = require('fs');
      const c = JSON.parse(fs.readFileSync('$CONFIG', 'utf8'));
      const keys = '$key'.split('.');
      let obj = c;
      for (let i = 0; i < keys.length - 1; i++) {
        if (!obj[keys[i]]) obj[keys[i]] = {};
        obj = obj[keys[i]];
      }
      obj[keys[keys.length - 1]] = $value;
      fs.writeFileSync('$CONFIG', JSON.stringify(c, null, 2));
    "
  }

  echo "  → Setting OpenRouter keys..."
  set_json 'env.OPENROUTER_API_KEY' "\"$OPENROUTER_API_KEY\""
  set_json 'env.OPENROUTER_API_KEY_2' "\"$OPENROUTER_API_KEY_2\""
  set_json 'env.OPENROUTER_API_KEY_3' "\"$OPENROUTER_API_KEY_3\""

  echo "  → Setting Groq key..."
  set_json 'env.GROQ_API_KEY' "\"$GROQ_API_KEY\""

  echo "  → Setting Gemini keys..."
  set_json 'env.GEMINI_API_KEY' "\"$GEMINI_API_KEY\""
  set_json 'env.GEMINI_API_KEY_2' "\"$GEMINI_API_KEY_2\""
  set_json 'env.GEMINI_API_KEY_3' "\"$GEMINI_API_KEY_3\""

  echo "  → Setting bot tokens..."
  set_json 'channels.discord.token' "\"$DISCORD_BOT_TOKEN\""
  set_json 'channels.telegram.botToken' "\"$DISCORD_BOT_TOKEN\""

  echo "✅ Config filled from .env!"
  echo ""
  echo "Next steps on the remote:"
  echo "  1. Source your env:  source ~/.openclaw/.env"
  echo "  2. Start gateway:    openclaw gateway start"
  echo "  3. Run doctor:       openclaw doctor"
BOOTSTRAP

echo ""
echo "✅ Bootstrap complete!"
echo "   Remote:  $REMOTE_USER@$REMOTE_HOST"
echo "   Config:  ~/.openclaw/openclaw.json (filled from .env)"
echo ""
echo "Next: ssh $REMOTE_USER@$REMOTE_HOST and run:"
echo "  source ~/.openclaw/.env"
echo "  openclaw gateway start"