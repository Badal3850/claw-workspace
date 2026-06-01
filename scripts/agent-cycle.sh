#!/bin/bash
# Run one bounded OpenClaw agent cycle for scheduled CI.
# Secrets stay in environment variables / runtime auth; only allowlisted memory files are committed.

set -euo pipefail

CLAW_BRANCH="${CLAW_BRANCH:-master}"
CLAW_AGENT_MESSAGE="${CLAW_AGENT_MESSAGE:-Heartbeat: review HEARTBEAT.md, update memory only if genuinely useful, and stay quiet otherwise.}"
CLAW_SYNC_PATHS="${CLAW_SYNC_PATHS:-MEMORY.md HEARTBEAT.md memory}"
GIT_REMOTE="${GIT_REMOTE:-origin}"
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$OPENCLAW_HOME/openclaw.json}"
OPENCLAW_ENV_PATH="${OPENCLAW_ENV_PATH:-$OPENCLAW_HOME/.env}"
export OPENCLAW_HOME OPENCLAW_CONFIG_PATH OPENCLAW_ENV_PATH

setup_git_identity() {
  git config --global user.name "${GIT_AUTHOR_NAME:-Claw-Agent}"
  git config --global user.email "${GIT_AUTHOR_EMAIL:-claw@agent.ai}"
}

git_with_optional_token() {
  if [ -n "${CLAW_PAT:-}" ]; then
    local auth
    auth="$(printf 'x-access-token:%s' "$CLAW_PAT" | base64 | tr -d '\n')"
    git -c "http.https://github.com/.extraheader=AUTHORIZATION: basic ${auth}" "$@"
  else
    git "$@"
  fi
}

pull_latest() {
  git_with_optional_token fetch "$GIT_REMOTE" "$CLAW_BRANCH"
  git_with_optional_token pull --ff-only "$GIT_REMOTE" "$CLAW_BRANCH"
}

init_openclaw() {
  node scripts/init-openclaw-config.js "$OPENCLAW_ENV_PATH" "$OPENCLAW_CONFIG_PATH"
}

preflight_openclaw() {
  npx openclaw config validate
  npx openclaw models status --check
  if [ "${CLAW_PROBE_MODELS:-false}" = "true" ]; then
    npx openclaw models status --probe --probe-timeout "${CLAW_PROBE_TIMEOUT_MS:-15000}"
  fi
}

run_agent_once() {
  npx openclaw agent --local \
    --session-key agent:main:scheduled-heartbeat \
    --message "$CLAW_AGENT_MESSAGE" \
    --timeout "${CLAW_AGENT_TIMEOUT:-600}"
}

commit_allowlisted_changes() {
  # shellcheck disable=SC2086
  git add $CLAW_SYNC_PATHS

  if git diff --cached --quiet; then
    echo "No allowlisted memory changes to commit."
    return 0
  fi

  git commit -m "Claw Memory Sync: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
  git_with_optional_token push "$GIT_REMOTE" "HEAD:$CLAW_BRANCH"
}

setup_git_identity
pull_latest
init_openclaw
preflight_openclaw
run_agent_once
commit_allowlisted_changes
