# We change 20-slim to 22-slim to meet the engine requirement
FROM node:22-slim

# Install Git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Hugging Face runs as user 1000
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

WORKDIR $HOME/app

# Copy files and set ownership
COPY --chown=user . .

# Now this command will work without warnings
RUN npm install

EXPOSE 7860
CMD ["bash", "scripts/run.sh"]