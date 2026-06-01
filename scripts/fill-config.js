#!/usr/bin/env node
/**
 * Backward-compatible wrapper for the centralized OpenClaw config initializer.
 *
 * Usage: node scripts/fill-config.js [env-path] [config-path]
 */

const { spawnSync } = require('child_process');
const path = require('path');

const initScript = path.join(__dirname, 'init-openclaw-config.js');
const result = spawnSync(process.execPath, [initScript, ...process.argv.slice(2)], {
  stdio: 'inherit',
  env: process.env,
});

process.exit(result.status ?? 1);
