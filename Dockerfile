FROM node:20-slim
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 7860
CMD ["bash", "scripts/run.sh"]