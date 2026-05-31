#!/usr/bin/env node
/**
 * OpenClaw Config Filler
 * Reads .env and fills secrets into openclaw.json
 *
 * Usage: node fill-config.js [env-path] [config-path]
 *   Defaults: .env and ~/.openclaw/openclaw.json
 */

const fs = require('fs');
const path = require('path');

const envPath = process.argv[2] || path.join(process.env.HOME || process.env.USERPROFILE, '.openclaw', '.env');
const configPath = process.argv[3] || path.join(process.env.HOME || process.env.USERPROFILE, '.openclaw', 'openclaw.json');

// Parse .env file
function parseEnv(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const env = {};
  for (const line of content.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx === -1) continue;
    const key = trimmed.slice(0, eqIdx).trim();
    let value = trimmed.slice(eqIdx + 1).trim();
    // Strip quotes if present
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    env[key] = value;
  }
  return env;
}

function setDeep(obj, keyPath, value) {
  const keys = keyPath.split('.');
  let current = obj;
  for (let i = 0; i < keys.length - 1; i++) {
    if (!current[keys[i]]) current[keys[i]] = {};
    current = current[keys[i]];
  }
  current[keys[keys.length - 1]] = value;
}

const map = {
  'OPENROUTER_API_KEY': 'env.OPENROUTER_API_KEY',
  'OPENROUTER_API_KEY_2': 'env.OPENROUTER_API_KEY_2',
  'OPENROUTER_API_KEY_3': 'env.OPENROUTER_API_KEY_3',
  'GROQ_API_KEY': 'env.GROQ_API_KEY',
  'GEMINI_API_KEY': 'env.GEMINI_API_KEY',
  'GEMINI_API_KEY_2': 'env.GEMINI_API_KEY_2',
  'GEMINI_API_KEY_3': 'env.GEMINI_API_KEY_3',
  'DISCORD_BOT_TOKEN': 'channels.discord.token',
  // Telegram botToken uses same value as DISCORD_BOT_TOKEN in your setup
};

try {
  const env = parseEnv(envPath);
  let config = {};
  try { config = JSON.parse(fs.readFileSync(configPath, 'utf8')); } catch {}

  for (const [envKey, jsonPath] of Object.entries(map)) {
    if (env[envKey]) {
      setDeep(config, jsonPath, env[envKey]);
      console.log(`  ✓ ${jsonPath}`);
    }
  }

  // Also set telegram botToken (same as discord token in your setup)
  if (env['DISCORD_BOT_TOKEN'] && !config.channels?.telegram?.botToken) {
    setDeep(config, 'channels.telegram.botToken', env['DISCORD_BOT_TOKEN']);
  }

  fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
  console.log('\n✅ Config written to ' + configPath);
} catch (err) {
  console.error('❌ Error:', err.message);
  process.exit(1);
}