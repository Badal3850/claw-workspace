#!/usr/bin/env node
/**
 * Redact known local secrets from historical backups and logs.
 * It intentionally leaves ~/.openclaw/.env and the runtime auth store intact.
 */

const fs = require('fs');
const path = require('path');

const home = process.env.OPENCLAW_HOME ||
  path.join(process.env.HOME || process.env.USERPROFILE, '.openclaw');
const envPath = path.join(home, '.env');
const runtimeAuthPath = path.join(home, 'agents', 'main', 'agent', 'auth-profiles.json');

function parseEnv(content) {
  const env = {};
  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx === -1) continue;
    const key = trimmed.slice(0, eqIdx).trim();
    let value = trimmed.slice(eqIdx + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    env[key] = value;
  }
  return env;
}

function collectSecrets() {
  const secrets = new Set();
  if (fs.existsSync(envPath)) {
    for (const value of Object.values(parseEnv(fs.readFileSync(envPath, 'utf8')))) {
      if (value && value.length >= 12) secrets.add(value);
    }
  }
  for (const file of ['openclaw.json.last-good', 'openclaw.json.pre-update']) {
    const filePath = path.join(home, file);
    if (!fs.existsSync(filePath)) continue;
    try {
      const config = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      for (const value of Object.values(config.env || {})) {
        if (value && value.length >= 12) secrets.add(value);
      }
      if (config.channels?.telegram?.botToken) secrets.add(config.channels.telegram.botToken);
      if (config.channels?.discord?.token) secrets.add(config.channels.discord.token);
    } catch {}
  }
  return [...secrets];
}

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const filePath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (['npm', 'node_modules', '.git'].includes(entry.name)) continue;
      walk(filePath, out);
    } else {
      out.push(filePath);
    }
  }
  return out;
}

function shouldSkip(filePath) {
  const normalized = path.normalize(filePath);
  return normalized === path.normalize(envPath) ||
    normalized === path.normalize(runtimeAuthPath) ||
    normalized.endsWith(path.normalize('workspace/scripts/sanitize-exposed-secrets.js'));
}

const secrets = collectSecrets();
const secretPatterns = [
  /sk-or-v1-[A-Za-z0-9_-]+/g,
  /gsk_[A-Za-z0-9_-]+/g,
  /AIza[A-Za-z0-9_-]+/g,
  /\b\d{8,12}:[A-Za-z0-9_-]{25,}\b/g,
  /\bMT[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b/g,
];
let touched = 0;
for (const filePath of walk(home)) {
  if (shouldSkip(filePath)) continue;
  let content;
  try {
    content = fs.readFileSync(filePath, 'utf8');
  } catch {
    continue;
  }
  let next = content;
  for (const secret of secrets) {
    next = next.split(secret).join('__ROTATED_SECRET__');
  }
  for (const pattern of secretPatterns) {
    next = next.replace(pattern, '__ROTATED_SECRET__');
  }
  if (next !== content) {
    fs.writeFileSync(filePath, next);
    touched += 1;
  }
}

console.log(`Redacted known secrets from ${touched} historical file(s).`);
