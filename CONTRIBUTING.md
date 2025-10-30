# Contributing

Thanks for helping with this project! This short guide explains how to get a development copy running and how to use the included agent helper scripts.

1) Work in the local clone

- Use the local clone at: `C:\repos\legendary-enigma-clone` (working inside OneDrive historically caused Git errors on Windows).

2) Environment setup

- Python:
  - Install Python 3.8+ and ensure `python` is on PATH.
  - Recreate the venv from the repo root:
    ```powershell
    python -m venv .venv
    .\.venv\Scripts\Activate.ps1
    python -m pip install --upgrade pip
    if (Test-Path requirements.txt) { pip install -r requirements.txt }
    ```

- Node (if used):
  - Run `npm ci` to get a reproducible install from `package-lock.json`.

3) Running agent scripts

- Interactive menu:
  ```powershell
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\agent-actions.ps1
  ```

- Non-interactive single action (example):
  ```powershell
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\agent-actions.ps1 -Action git-fetch-prune -NonInteractive
  ```

4) Commit & push workflow

- Use the included `.gitignore` to avoid committing venvs, caches, and editor files.
- If you use SSH for GitHub, add your public key to your account and use an SSH remote; otherwise ensure your commit email is acceptable for pushes (GitHub no-reply recommended for privacy).

5) Tests, linting, and CI

- There is no CI configured by default. If you add tests, consider adding a GitHub Actions workflow to run them on push.

6) Questions

- If you need help reproducing an environment or creating tasks/workflows, open an issue or ask here and I can scaffold the changes.
