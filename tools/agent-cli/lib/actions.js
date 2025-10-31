const fs = require('fs');
const path = require('path');

function detectActions(root) {
  const actions = [];
  if (fs.existsSync(path.join(root, 'package.json'))) {
    actions.push({ id: 'npm', label: 'npm install & test', cmd: 'npm ci && npm test' });
  }
  if (fs.existsSync(path.join(root, 'pyproject.toml'))) {
    actions.push({ id: 'python', label: 'python -m pip install -r requirements.txt', cmd: 'python -m pip install -r requirements.txt' });
  }
  return actions;
}

module.exports = { detectActions };
