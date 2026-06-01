#!/usr/bin/env node
/**
 * Sync local provider secrets into the runtime auth store without copying them
 * into openclaw.json. Run after updating ~/.openclaw/.env with rotated values.
 */

const fs = require('fs');
const path = require('path');

const home = process.env.OPENCLAW_HOME ||
  path.join(process.env.HOME || process.env.USERPROFILE, '.openclaw');
const envPath = process.argv[2] || path.join(home, '.env');
const legacyConfigPath = path.join(home, 'openclaw.json.last-good');

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

function readLegacyTelegramToken() {
  if (!fs.existsSync(legacyConfigPath)) return '';
  try {
    const config = JSON.parse(fs.readFileSync(legacyConfigPath, 'utf8'));
    return config.channels?.telegram?.botToken || '';
  } catch {
    return '';
  }
}

const env = fs.existsSync(envPath)
  ? parseEnv(fs.readFileSync(envPath, 'utf8'))
  : {};

if (!env.TELEGRAM_BOT_TOKEN) {
  const legacyToken = readLegacyTelegramToken();
  if (legacyToken) env.TELEGRAM_BOT_TOKEN = legacyToken;
}

const envKeys = [
  'OPENROUTER_API_KEY',
  'GROQ_API_KEY',
  'GEMINI_API_KEY',
  'TELEGRAM_BOT_TOKEN',
  'DISCORD_BOT_TOKEN',
];

const envLines = [
  '# OpenClaw PA secrets',
  '# Rotate every value below in the provider consoles before treating this setup as secure.',
  '',
  ...envKeys.map((key) => `${key}=${env[key] || ''}`),
];
fs.writeFileSync(envPath, `${envLines.join('\n')}\n`);

const runtimeProfiles = { version: 1, profiles: {} };
if (env.OPENROUTER_API_KEY) {
  runtimeProfiles.profiles['openrouter:default'] = {
    type: 'api_key',
    provider: 'openrouter',
    key: env.OPENROUTER_API_KEY,
  };
}
if (env.GROQ_API_KEY) {
  runtimeProfiles.profiles['groq:default'] = {
    type: 'api_key',
    provider: 'groq',
    key: env.GROQ_API_KEY,
  };
}
if (env.GEMINI_API_KEY) {
  runtimeProfiles.profiles['google:default'] = {
    type: 'api_key',
    provider: 'google',
    key: env.GEMINI_API_KEY,
  };
}

fs.mkdirSync(path.join(home, 'agents', 'main', 'agent'), { recursive: true });
fs.writeFileSync(
  path.join(home, 'agents', 'main', 'agent', 'auth-profiles.json'),
  `${JSON.stringify(runtimeProfiles, null, 2)}\n`,
);

const secretRefProfiles = {
  'openrouter:default': { apiKey: { secretRef: 'OPENROUTER_API_KEY' } },
  'groq:default': { apiKey: { secretRef: 'GROQ_API_KEY' } },
  'google:default': { apiKey: { secretRef: 'GEMINI_API_KEY' } },
};
fs.mkdirSync(path.join(home, 'agents', 'main'), { recursive: true });
fs.writeFileSync(
  path.join(home, 'agents', 'main', 'auth-profiles.json'),
  `${JSON.stringify(secretRefProfiles, null, 2)}\n`,
);

console.log('Synced .env and runtime auth profiles without printing secrets.');
