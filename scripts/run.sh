#!/bin/bash

# 1. Complete Git Clean-up (Fixes the "Credential Storage Lock" error)
git config --global --unset-all credential.helper
git config --global user.name "Claw-Agent"
git config --global user.email "claw@agent.ai"

# Set the remote with your Token for full access
git remote set-url origin https://Badal3850:$CLAW_PAT@github.com/Badal3850/claw-workspace.git

# 2. Pull latest changes
git pull origin master

# 3. Generate the OpenClaw config
# We ensure the port is set inside the config just in case
cat <<EOF > openclaw.json
{
  "name": "${CLAW_NAME:-Claw}",
  "model": "gemini-1.5-flash",
  "api_key": "${GEMINI_API_KEY}",
  "workspace_path": "./",
  "server": {
    "port": 7860
  }
}
EOF

# 4. Start the OpenClaw Agent
# FIXED: Changed 'run' to 'start' as requested by the OpenClaw CLI
# We use PORT=7860 as an environment variable to force it for Hugging Face
export PORT=7860
npx openclaw start &

# 5. The Sync Loop
while true; do
  sleep 600
  git add .
  git commit -m "Claw Memory Sync: $(date)"
  git push origin master
  echo "Memories backed up to GitHub."
done