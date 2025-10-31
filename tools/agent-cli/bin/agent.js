#!/usr/bin/env node

// Minimal placeholder CLI
const path = require('path');
const fs = require('fs');

const root = process.cwd();
console.log('agent-cli placeholder — working dir:', root);

// Simple detection example
const pkg = path.join(root, 'package.json');
if (fs.existsSync(pkg)) {
  console.log('Detected package.json — run: npm ci && npm test');
} else {
  console.log('No package.json detected.');
}
