FROM node:20-slim

# Install Git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy workspace
COPY . .

# Install OpenClaw core globally or locally
RUN npm install -g openclaw

# Make script executable
RUN chmod +x scripts/run.sh

# Run the sync script
CMD ["./scripts/run.sh"]