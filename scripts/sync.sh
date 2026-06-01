#!/bin/bash

# 1. Pull latest memories from GitHub
git pull origin main

# 2. Start the OpenClaw Agent
# (Assuming your agent start command is 'npm start' or similar)
npm start 

# 3. After the agent performs a task, commit the changes
git config --global user.name "Claw-Agent"
git config --global user.email "claw@agent.ai"
git add .
git commit -m "Claw Memory Update: $(date)"
git push origin main