#!/bin/bash

# 1. Setup Git identity & Auth
git config --global user.name "Claw-Agent"
git config --global user.email "claw@agent.ai"
# We point this specifically to YOUR GitHub repo
git remote set-url origin https://Badal3850:$CLAW_PAT@github.com/Badal3850/claw-workspace.git

# 2. Pull latest changes (Using MASTER branch)
git pull origin master

# 3. Generate the OpenClaw config file
cat <<EOF > openclaw.json
{
  "name": "${CLAW_NAME:-Claw}",
  "model": "gemini-1.5-flash",
  "api_key": "${GEMINI_API_KEY}",
  "workspace_path": "./"
}
EOF

# 4. Start the OpenClaw Server
# We use @openclaw/core to ensure the engine runs
npx @openclaw/core run --port 7860 &

# 5. The Sync Loop (Saves to MASTER branch)
while true; do
  sleep 600
  git add .
  git commit -m "Claw Memory Sync: $(date)"
  git push origin master
  echo "Memories backed up to GitHub."
done