# Use Node 22 (Required by OpenClaw)
FROM node:22-slim

# Install Git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Use the 'node' user that already exists in this image (UID 1000)
USER node
ENV HOME=/home/node \
    PATH=/home/node/.local/bin:$PATH

# Set the working directory inside the node user's home
WORKDIR $HOME/app

# Copy your files and make sure the 'node' user owns them
COPY --chown=node:node . .

# Install OpenClaw
RUN npm install

# Hugging Face port
EXPOSE 7860

# Start the agent
CMD ["bash", "scripts/run.sh"]