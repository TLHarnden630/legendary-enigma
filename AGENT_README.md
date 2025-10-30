# Agent scripts and local maintenance

[![CI](https://github.com/TLHarnden630/legendary-enigma/actions/workflows/ci.yml/badge.svg)](https://github.com/TLHarnden630/legendary-enigma/actions/workflows/ci.yml)
[![CodeQL](https://github.com/TLHarnden630/legendary-enigma/actions/workflows/codeql-analysis.yml/badge.svg)](https://github.com/TLHarnden630/legendary-enigma/actions/workflows/codeql-analysis.yml)
[![Artifacts](https://img.shields.io/badge/artifacts-latest-blue)](https://github.com/TLHarnden630/legendary-enigma/actions/workflows/ci.yml)

This document describes the agent helper scripts included in the repository and how to use them locally. The badges above link to the CI and CodeQL workflow pages; the "Artifacts" badge links to the CI workflow where build/test artifacts appear for the latest runs (an artifact will appear after a successful workflow run).

# Agent Scripts & Quick Actions

This repository includes a small set of helper PowerShell scripts under `scripts/` that provide an interactive and non-interactive menu for common repository maintenance and repair tasks.

Quick tips

- Work from the local clone: `C:\repos\legendary-enigma-clone` (avoid working copies inside OneDrive).
- Do NOT copy virtual environments or `node_modules` between machines; recreate them locally.

Common commands

- Run the interactive agent menu:
  ```powershell
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\agent-actions.ps1
  ```

- Run a single action non-interactively (example: fetch/prune):
  ```powershell
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\agent-actions.ps1 -Action git-fetch-prune -NonInteractive
  ```

- Run the Winget helper (interactive):
  ```powershell
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\winget-menu.ps1
  ```

Recreating Python venv (do not copy `.venv` from other machines)

1. Install Python 3.8+ and ensure `python` is on PATH.
2. From the repo root:
   ```powershell
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   if (Test-Path requirements.txt) { pip install -r requirements.txt }
   ```

Committing changes

- A `.gitignore` is present to avoid committing venvs, caches, and IDE files. Review before committing.

SSH & pushing tips

- If you use SSH for GitHub, add an SSH key to your account and use the `git@github.com:...` remote. If your account blocks command-line pushes that expose a private email, use your GitHub no-reply email like `USERNAME@users.noreply.github.com` or set a public email in your GitHub account.

Support

If you want me to scaffold VS Code tasks, add more CI checks, or help recreate your environment, tell me what to do next.
