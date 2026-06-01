#!/bin/bash
# OpenClaw Bootstrap Script
# Copies workspace files, installs OpenClaw, copies .env, and syncs runtime auth.
#
# Usage: bash bootstrap.sh <remote-user> <remote-host> [openclaw-home]

set -euo pipefail

REMOTE_USER="${1?Usage: $0 <remote-user> <remote-host> [openclaw-home]}"
REMOTE_HOST="${2?Usage: $0 <remote-user> <remote-host> [openclaw-home]}"
OPENCLAW_HOME="${3:-$HOME/.openclaw}"
WORKSPACE_DIR="$OPENCLAW_HOME/workspace"

echo "==> Installing OpenClaw on $REMOTE_USER@$REMOTE_HOST..."
ssh "$REMOTE_USER@$REMOTE_HOST" <<'SSH'
  set -e
  curl -fsSL https://openclaw.ai/install.sh | bash
  mkdir -p ~/.openclaw/workspace
SSH

echo "==> Copying workspace files..."
rsync -avz --delete \
  --exclude='.git/' \
  --exclude='*.env' \
  --exclude='*.bak' \
  --exclude='*.bak.*' \
  --exclude='.openclaw/' \
  "$WORKSPACE_DIR/" \
  "$REMOTE_USER@$REMOTE_HOST:~/.openclaw/workspace/"

echo "==> Copying .env..."
scp "$OPENCLAW_HOME/.env" "$REMOTE_USER@$REMOTE_HOST:~/.openclaw/.env"

echo "==> Syncing non-secret config and runtime auth..."
ssh "$REMOTE_USER@$REMOTE_HOST" bash -s <<'BOOTSTRAP'
  set -euo pipefail
  OPENCLAW_HOME="${HOME}/.openclaw"
  CONFIG="$OPENCLAW_HOME/openclaw.json"

  if [ ! -f "$CONFIG" ]; then
    echo "{}" > "$CONFIG"
  fi

  node "$OPENCLAW_HOME/workspace/scripts/fill-config.js" \
    "$OPENCLAW_HOME/.env" \
    "$CONFIG"

  echo "Bootstrap synced config without writing bot tokens into openclaw.json."
  echo ""
  echo "Next steps on the remote:"
  echo "  1. Rotate and verify values in ~/.openclaw/.env"
  echo "  2. Run: openclaw config validate"
  echo "  3. Start gateway: openclaw gateway start"
BOOTSTRAP

echo ""
echo "Bootstrap complete."
echo "Remote: $REMOTE_USER@$REMOTE_HOST"
echo "Config: ~/.openclaw/openclaw.json"
