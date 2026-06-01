#!/bin/bash

# 1. Setup Git identity & Auth FIRST
# This ensures Step 2 (git pull) actually works!
git config --global user.name "Claw-Agent"
git config --global user.email "claw@agent.ai"
git remote set-url origin https://Badal3850:$CLAW_PAT@github.com/Badal3850/claw-workspace.git

# 2. Pull latest changes from your GitHub Diary
git pull origin main

# 3. Generate the OpenClaw config file
cat <<EOF > openclaw.json
{
  "name": "${CLAW_NAME:-Claw}",
  "model": "gemini-1.5-flash",
  "api_key": "${GEMINI_API_KEY}",
  "workspace_path": "./"
}
EOF

# 4. Start the OpenClaw Server in the background
# We use port 7860 because Hugging Face requires it.
# The '&' at the end lets the script keep running for the sync loop.
npx openclaw serve --port 7860 &

# 5. The "Sync Loop" (Saves memories every 10 minutes)
# This keeps the container alive and ensures your memories are backed up.
while true; do
  sleep 600
  git add .
  git commit -m "Claw Memory Sync: $(date)"
  git push origin main
  echo "Syncing memories to GitHub..."
done