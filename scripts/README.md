# scripts — quick helpers

This folder contains a small interactive PowerShell helper you can run to pick common repository tasks and run them immediately.

How to run (Windows / PowerShell)

```powershell
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\agent-actions.ps1
```

What it does
- Detects common files like `package.json`, `pyproject.toml`, `go.mod`, and `Dockerfile`.
- Presents a numbered menu with only relevant actions (install/test/build commands, docker build, repo scan, open `copilot-instructions.md`).
- Runs the selected command in the repository root and shows output.

When to use
- When you want a fast way to run typical build/test tasks without memorizing commands.

Notes
- The script is intentionally conservative — it runs commands in the repository root and pauses after each action so you can review output.
- If you want additional actions added, edit `scripts/agent-actions.ps1` and open a PR.

Winget helper
- There's also an interactive Winget manager: `scripts/winget-menu.ps1`.

Run the Winget manager with:

```powershell
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\winget-menu.ps1
```

It lists installed packages (via `winget list --output json`), allows you to inspect package details, upgrade or uninstall, and search & install new packages.

Repair & quick-fix actions
- The `agent-actions.ps1` menu now includes a set of interactive repair actions when relevant files are present. Examples:
	- "Repair Node modules" — removes `node_modules` then runs `npm ci` (confirmation required).
	- "Recreate Python venv" — removes `.venv`, creates a new venv and installs dependencies (confirmation required).
	- "Git: fetch --all --prune" — runs a safe fetch/prune and shows repo status.
	- "Winget: upgrade all outdated packages" — upgrades all packages via `winget` (confirmation required).

These actions are interactive and will ask for confirmation before performing destructive changes. Use them as quick first steps when a developer machine is in a broken state.

Destructive git reset
- There's also a destructive action: "Git: FORCE-RESET current branch to origin (destructive)". This hard-resets the current branch to the remote tracking branch and runs `git clean -fdx`.
- This action asks for confirmation interactively. If you need to run it unattended, see the non-interactive invocation below (use with extreme caution).

Non-interactive automation
- You can run a single action from the command-line without the interactive menu. This is useful for automation, remote fixes, or scripted recovery.

Example (runs without interactive confirmations):

```powershell
pwsh.exe -NoProfile -File .\scripts\agent-actions.ps1 -Action repair-node -NonInteractive
```

Replace `repair-node` with any action id printed by the menu (or listed when an unknown action id is supplied). Use `-NonInteractive` to skip confirmation prompts; be careful with destructive actions.

Repair checklist
- A short mapping of symptoms to quick actions is included in `scripts/REPAIR_CHECKLIST.md`.

Hope this works for you, It's my first attempt at coding without someone standing behind or over me.

- Gratefully yours, TLHarnden 2025