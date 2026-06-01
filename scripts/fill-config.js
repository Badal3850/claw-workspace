#!/usr/bin/env node
/**
 * OpenClaw Config Filler
 * Reads .env, updates non-secret OpenClaw config, and syncs provider secrets
 * into the runtime auth store instead of copying them into openclaw.json.
 *
 * Usage: node fill-config.js [env-path] [config-path]
 *   Defaults: .env and ~/.openclaw/openclaw.json
 */

const fs = require('fs');
const path = require('path');

const home = process.env.HOME || process.env.USERPROFILE;
const envPath = process.argv[2] || path.join(home, '.openclaw', '.env');
const configPath = process.argv[3] || path.join(home, '.openclaw', 'openclaw.json');
const openclawHome = path.dirname(configPath);

function parseEnv(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
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

function setDeep(obj, keyPath, value) {
  const keys = keyPath.split('.');
  let current = obj;
  for (let i = 0; i < keys.length - 1; i++) {
    if (!current[keys[i]]) current[keys[i]] = {};
    current = current[keys[i]];
  }
  current[keys[keys.length - 1]] = value;
}

function deleteDeep(obj, keyPath) {
  const keys = keyPath.split('.');
  let current = obj;
  for (let i = 0; i < keys.length - 1; i++) {
    if (!current?.[keys[i]]) return;
    current = current[keys[i]];
  }
  delete current[keys[keys.length - 1]];
}

function writeRuntimeAuth(env) {
  const profiles = { version: 1, profiles: {} };
  if (env.OPENROUTER_API_KEY) {
    profiles.profiles['openrouter:default'] = {
      type: 'api_key',
      provider: 'openrouter',
      key: env.OPENROUTER_API_KEY,
    };
  }
  if (env.GROQ_API_KEY) {
    profiles.profiles['groq:default'] = {
      type: 'api_key',
      provider: 'groq',
      key: env.GROQ_API_KEY,
    };
  }
  if (env.GEMINI_API_KEY) {
    profiles.profiles['google:default'] = {
      type: 'api_key',
      provider: 'google',
      key: env.GEMINI_API_KEY,
    };
  }

  const runtimePath = path.join(openclawHome, 'agents', 'main', 'agent', 'auth-profiles.json');
  fs.mkdirSync(path.dirname(runtimePath), { recursive: true });
  fs.writeFileSync(runtimePath, `${JSON.stringify(profiles, null, 2)}\n`);
}

try {
  const env = parseEnv(envPath);
  let config = {};
  try {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  } catch {}

  delete config.env;
  deleteDeep(config, 'channels.telegram.botToken');
  deleteDeep(config, 'channels.discord.token');

  setDeep(config, 'agents.defaults.memorySearch', {
    provider: 'gemini',
    enabled: true,
    model: 'gemini-embedding-001',
  });
  setDeep(config, 'agents.defaults.models', {
    'google/gemini-2.5-flash': { alias: 'Gemini Flash' },
    'google/gemini-2.0-flash': { alias: 'Gemini Free' },
    'openrouter/deepseek/deepseek-v4-flash': { alias: 'OpenRouter Fallback' },
    'groq/openai/gpt-oss-20b': { alias: 'Groq Fast' },
  });
  setDeep(config, 'agents.defaults.model', {
    primary: 'google/gemini-2.5-flash',
    fallbacks: [
      'google/gemini-2.0-flash',
      'openrouter/deepseek/deepseek-v4-flash',
    ],
  });
  setDeep(config, 'agents.defaults.heartbeat', {
    every: '30m',
    model: 'google/gemini-2.0-flash',
  });
  setDeep(config, 'agents.defaults.subagents', { model: 'google/gemini-2.0-flash' });
  setDeep(config, 'plugins.entries.openrouter.enabled', true);
  setDeep(config, 'plugins.entries.telegram.enabled', true);
  setDeep(config, 'plugins.entries.discord.enabled', false);
  setDeep(config, 'plugins.entries.google.enabled', true);
  setDeep(config, 'plugins.entries.groq.enabled', true);
  setDeep(config, 'models.providers.google.api', 'google-generative-ai');
  setDeep(config, 'models.providers.google.models', [
    { id: 'gemini-2.5-flash', name: 'Gemini 2.5 Flash' },
    { id: 'gemini-2.0-flash', name: 'Gemini 2.0 Flash' },
  ]);
  setDeep(config, 'models.providers.groq', {
    api: 'openai-completions',
    baseUrl: 'https://api.groq.com/openai/v1',
    models: [
      { id: 'openai/gpt-oss-20b', name: 'Groq GPT OSS 20B' },
    ],
  });
  setDeep(config, 'models.providers.openrouter.models', [
    { id: 'deepseek/deepseek-v4-flash', name: 'DeepSeek V4 Flash' },
  ]);
  setDeep(config, 'auth.profiles.openrouter:default', { provider: 'openrouter', mode: 'api_key' });
  setDeep(config, 'auth.profiles.groq:default', { provider: 'groq', mode: 'api_key' });
  setDeep(config, 'auth.profiles.google:default', { provider: 'google', mode: 'api_key' });
  deleteDeep(config, 'auth.profiles.openrouter:backup1');
  deleteDeep(config, 'auth.profiles.openrouter:backup2');
  deleteDeep(config, 'auth.profiles.google:backup1');
  deleteDeep(config, 'auth.profiles.google:backup2');
  setDeep(config, 'auth.order', {
    openrouter: ['openrouter:default'],
    groq: ['groq:default'],
    google: ['google:default'],
  });
  setDeep(config, 'channels.telegram.enabled', true);
  setDeep(config, 'channels.telegram.groups', { '*': { requireMention: true } });
  setDeep(config, 'channels.discord.enabled', false);

  fs.writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`);
  writeRuntimeAuth(env);
  console.log('Config and runtime auth written without copying secrets into openclaw.json.');
} catch (err) {
  console.error('Error:', err.message);
  process.exit(1);
}
