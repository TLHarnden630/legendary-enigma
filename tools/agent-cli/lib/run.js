const { spawn } = require('child_process');

function runCommand(cmd, args = [], opts = {}) {
  return new Promise((resolve) => {
    const p = spawn(cmd, args, { stdio: 'inherit', shell: true, ...opts });
    p.on('close', (code) => resolve(code));
  });
}

module.exports = { runCommand };
