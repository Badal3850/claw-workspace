#!/bin/bash

# 1. Setup Git identity (so Claw can commit)
git config --global user.name "Claw-Agent"
git config --global user.email "claw@agent.ai"

# 2. Pull latest changes from the repo
git pull origin main

# 3. Generate the OpenClaw config file from Environment Variables
# This prevents the user from having to manually edit JSON files
cat <<EOF > openclaw.json
{
  "name": "${CLAW_NAME:-Claw}",
  "model": "gemini-1.5-flash",
  "api_key": "${GEMINI_API_KEY}",
  "workspace_path": "./"
}
EOF

# 4. Run the OpenClaw Core
# (Note: This assumes you have the OpenClaw core installed or use npx)
npx openclaw run

# 5. Push any new memories/logs back to GitHub
git add .
git commit -m "Claw Memory Update: $(date)"
git push origin main