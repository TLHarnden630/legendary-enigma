# Repair checklist — quick guidance

This short checklist maps common developer machine problems to the quick actions available in `scripts/agent-actions.ps1`.

1) Symptom: Build fails with missing node modules or unexpected module resolution errors
   - Action: "Repair Node modules"
   - What it does: removes `node_modules` then runs `npm ci` to install a clean dependency tree.
   - When to use: after package.json or lockfile changes, or when `npm install`/`npm ci` fails repeatedly.

2) Symptom: Python imports fail, or virtualenv is inconsistent
   - Action: "Recreate Python venv"
   - What it does: deletes `.venv`, creates a new venv, activates it and installs dependencies from `requirements.txt` (or editable install if `pyproject.toml` present).
   - When to use: after upgrading Python, changing dependency sets, or corrupted virtualenv.

3) Symptom: Git branches are strange, local changes prevent clean checkout, or repository state is confusing
   - Action: "Git: fetch --all --prune"
   - What it does: fetches all remotes and prunes deleted remote branches, then shows `git status --porcelain` so you can inspect local changes.
   - When to use: to update remote refs and check local status without destructive changes.

4) Symptom: Repository is badly corrupted or you want to make local branch match remote exactly
   - Action: "Git: FORCE-RESET current branch to origin (destructive)"
   - What it does: fetches all remotes, hard-resets the current branch to `origin/<current-branch>`, and runs `git clean -fdx` to remove untracked files.
   - Warning: This is destructive. Use only when you understand local changes will be lost. The action asks for confirmation unless run with `-NonInteractive`.

5) Symptom: System-installed apps are out of date or failing
   - Action: "Winget: upgrade all outdated packages"
   - What it does: runs `winget upgrade --all` and accepts package/source agreements.
   - When to use: when multiple system apps need updates; this changes installed programs.

6) Symptom: Need to inspect or manage system packages manually
   - Action: "Winget package manager (interactive)"
   - What it does: opens `scripts/winget-menu.ps1`, which lists installed packages, allows inspection, upgrades, uninstalls, and searching/installing new packages.

Running non-interactively
- You can run a single action directly from the command line, useful for automation or scripted repair flows:

```powershell
pwsh.exe -NoProfile -File .\scripts\agent-actions.ps1 -Action repair-node -NonInteractive
```

This runs the `repair-node` action without prompting. Use `-NonInteractive` with care for destructive actions.

If you need a new mapping added to this checklist, edit this file with the symptom and the corresponding `agent-actions` entry.
