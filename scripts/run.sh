#!/bin/bash

# 1. Setup Git identity & Auth
# We tell Git NOT to use a credential helper to avoid the "storage lock" error
git config --global credential.helper ""
git config --global user.name "Claw-Agent"
git config --global user.email "claw@agent.ai"
git remote set-url origin https://Badal3850:$CLAW_PAT@github.com/Badal3850/claw-workspace.git

# 2. Pull latest changes
git pull origin master

# 3. Generate the OpenClaw config
cat <<EOF > openclaw.json
{
  "name": "${CLAW_NAME:-Claw}",
  "model": "gemini-1.5-flash",
  "api_key": "${GEMINI_API_KEY}",
  "workspace_path": "./"
}
EOF

# 4. Start the OpenClaw Server
# FIXED: Changed '@openclaw/core' to 'openclaw'
# We use 'npx openclaw@latest' to ensure it finds the right package
npx openclaw@latest run --port 7860 &

# 5. The Sync Loop
while true; do
  sleep 600
  git add .
  git commit -m "Claw Memory Sync: $(date)"
  git push origin master
  echo "Memories backed up to GitHub."
done