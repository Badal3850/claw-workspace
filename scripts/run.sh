#!/bin/bash
# Start the long-running OpenClaw gateway for container/Hugging Face deployments.
# This script initializes the active OpenClaw config and does not commit files.

set -euo pipefail

CLAW_BRANCH="${CLAW_BRANCH:-master}"
PORT="${PORT:-7860}"
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$OPENCLAW_HOME/openclaw.json}"
OPENCLAW_ENV_PATH="${OPENCLAW_ENV_PATH:-$OPENCLAW_HOME/.env}"
OPENCLAW_GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-lan}"
export PORT OPENCLAW_HOME OPENCLAW_CONFIG_PATH OPENCLAW_ENV_PATH OPENCLAW_GATEWAY_BIND

setup_git_identity() {
  git config --global user.name "${GIT_AUTHOR_NAME:-Claw-Agent}"
  git config --global user.email "${GIT_AUTHOR_EMAIL:-claw@agent.ai}"
}

safe_pull() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  if git remote get-url origin >/dev/null 2>&1; then
    git fetch origin "$CLAW_BRANCH" || true
    git pull --ff-only origin "$CLAW_BRANCH" || true
  fi
}

init_openclaw() {
  node scripts/init-openclaw-config.js "$OPENCLAW_ENV_PATH" "$OPENCLAW_CONFIG_PATH"
  npx openclaw config validate
}

setup_git_identity
safe_pull
init_openclaw

exec npx openclaw gateway run --port "$PORT" --bind "$OPENCLAW_GATEWAY_BIND" --allow-unconfigured
