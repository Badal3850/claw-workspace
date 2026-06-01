#!/usr/bin/env node
/**
 * Rebuild OpenClaw runtime auth profiles from ~/.openclaw/.env without copying
 * secrets into openclaw.json. This follows the same free-first / paid-last
 * policy as normal startup.
 */

const { spawnSync } = require('child_process');
const path = require('path');

const home = process.env.OPENCLAW_HOME ||
  path.join(process.env.HOME || process.env.USERPROFILE, '.openclaw');
const envPath = process.argv[2] || path.join(home, '.env');
const configPath = process.argv[3] || process.env.OPENCLAW_CONFIG_PATH || path.join(home, 'openclaw.json');
const initScript = path.join(__dirname, 'init-openclaw-config.js');

const result = spawnSync(process.execPath, [initScript, envPath, configPath], {
  stdio: 'inherit',
  env: process.env,
});

process.exit(result.status ?? 1);
