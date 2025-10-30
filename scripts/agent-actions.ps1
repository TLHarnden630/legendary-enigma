<#
  scripts/agent-actions.ps1
  Interactive PowerShell menu to pick common repo actions and run them immediately.

  Usage (PowerShell):
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\agent-actions.ps1

  This script auto-detects common project files (package.json, pyproject.toml, go.mod, Dockerfile)
  and exposes only relevant actions. It is a lightweight helper for maintainers and AI agents.
#>

param(
    [string]$Action,
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Has-File([string]$name) {
    return Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\$name") -PathType Leaf -ErrorAction SilentlyContinue
}

function Run-Command {
    param(
        [string]$Command,
        [string]$WorkingDir = $PSScriptRoot
    )

    Write-Host "=> $Command" -ForegroundColor Cyan
    Push-Location $WorkingDir -ErrorAction SilentlyContinue
    try {
        # Prefer Start-Process for external executables so we always get a reliable ExitCode
        $tokens = $Command -split ' ' -ne ''
        if ($tokens.Count -gt 0) {
            $exe = $tokens[0]
            $args = if ($tokens.Count -gt 1) { $tokens[1..($tokens.Count - 1)] -join ' ' } else { '' }
        } else {
            $exe = $Command
            $args = ''
        }

        $exitCode = $null
        try {
            $proc = Start-Process -FilePath $exe -ArgumentList $args -NoNewWindow -Wait -PassThru -ErrorAction Stop
            $exitCode = $proc.ExitCode
        } catch {
            # Fall back to PowerShell execution for commands that are scripts or require the shell
            try {
                Invoke-Expression $Command
                $lastVar = Get-Variable -Name 'LASTEXITCODE' -ErrorAction SilentlyContinue
                if ($lastVar -and $lastVar.Value -ne $null) { $exitCode = $lastVar.Value } else { $exitCode = 0 }
            } catch {
                Write-Host "Command execution failed: $_" -ForegroundColor Red
                $exitCode = 1
            }
        }

        if ($null -eq $exitCode) { $exitCode = 0 }
        Write-Host "Exit code: $exitCode" -ForegroundColor Yellow
        return $exitCode
    } finally {
        Pop-Location -ErrorAction SilentlyContinue
    }
}

function Confirm-And-Run([string]$cmd, [string]$prompt = 'Proceed? (y/N)', [string]$workingDir = $PSScriptRoot) {
    $resp = Read-Host -Prompt $prompt
    if ($resp -match '^[Yy]') {
        Run-Command $cmd $workingDir
    } else {
        Write-Host 'Cancelled by user.' -ForegroundColor Yellow
        Pause
    }
}

function Force-GitReset([switch]$NonInteractive) {
    $wd = Join-Path $PSScriptRoot '..'
    if (-not $NonInteractive) {
        $resp = Read-Host -Prompt 'Destructive: reset current branch to origin (hard) and clean untracked files. Continue? (y/N)'
        if (-not ($resp -match '^[Yy]')) { Write-Host 'Cancelled by user.' -ForegroundColor Yellow; Pause; return }
    }

    Push-Location $wd
    try {
        Write-Host 'Fetching all remotes...' -ForegroundColor Cyan
        git fetch --all
        $branch = git rev-parse --abbrev-ref HEAD
        Write-Host "Resetting branch $branch to origin/$branch (hard)" -ForegroundColor Yellow
        git reset --hard "origin/$branch"
        Write-Host 'Cleaning untracked files...' -ForegroundColor Cyan
        git clean -fdx
        Write-Host 'Resulting status:' -ForegroundColor Green
        git status --porcelain
    } catch {
        Write-Host "Git reset failed: $_" -ForegroundColor Red
    } finally {
        Pop-Location
    }

    if (-not $NonInteractive) { Pause }
}

function Detect-Actions() {
    $actions = @()

    if (Has-File 'package.json') {
           $actions += [PSCustomObject]@{ id = 'npm-install-test'; label = 'npm ci && npm test (if package.json present)'; cmd = 'npm ci; npm test' }
           $actions += [PSCustomObject]@{ id = 'npm-build'; label = 'npm ci && npm run build (if build script exists)'; cmd = 'npm ci; npm run build' }
    }

    if (Has-File 'pyproject.toml' -or Has-File 'requirements.txt') {
           $actions += [PSCustomObject]@{ id = 'python-test'; label = 'Create venv, install deps, run pytest'; cmd = 'python -m venv .venv; .\.venv\Scripts\Activate.ps1; pip install -r requirements.txt -r requirements.txt 2>$null; if (Test-Path pyproject.toml) { pip install -e . -q } ; pytest' }
    }

    if (Has-File 'go.mod') {
           $actions += [PSCustomObject]@{ id = 'go-test'; label = 'go test ./...'; cmd = 'go test ./...' }
           $actions += [PSCustomObject]@{ id = 'go-build'; label = 'go build ./...'; cmd = 'go build ./...' }
    }

    if (Has-File 'Dockerfile') {
           $actions += [PSCustomObject]@{ id = 'docker-build'; label = 'docker build -t repo-local .'; cmd = 'docker build -t repo-local .' }
    }

    # Winget manager (dynamic) — present if scripts/winget-menu.ps1 exists
    if (Has-File 'scripts/winget-menu.ps1') {
           $actions += [PSCustomObject]@{ id = 'winget-manager'; label = 'Winget package manager (interactive)'; cmd = 'pwsh.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\winget-menu.ps1' }
    }

    # Repair and quick-fix actions (interactive confirmation required)
    if (Has-File 'package.json') {
           $actions += [PSCustomObject]@{ id = 'repair-node'; label = 'Repair Node modules (remove node_modules and npm ci)'; cmd = 'if (Test-Path node_modules) { Remove-Item -Recurse -Force node_modules }; npm ci' }
    }
    if (Has-File 'pyproject.toml' -or Has-File 'requirements.txt') {
           $actions += [PSCustomObject]@{ id = 'recreate-venv'; label = 'Recreate Python venv and install deps'; cmd = 'if (Test-Path .venv) { Remove-Item -Recurse -Force .venv }; python -m venv .venv; .\.venv\Scripts\Activate.ps1; pip install -r requirements.txt' }
    }
    # Git maintenance (non-destructive): fetch and prune
        $actions += [PSCustomObject]@{ id = 'git-fetch-prune'; label = 'Git: fetch --all --prune (non-destructive)'; cmd = 'git fetch --all --prune; git status --porcelain' }
    # Upgrade all winget packages (if winget script present or winget installed)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
           $actions += [PSCustomObject]@{ id = 'winget-upgrade-all'; label = 'Winget: upgrade all outdated packages (confirm)'; cmd = 'winget upgrade --all --accept-package-agreements --accept-source-agreements' }
    }
    # Destructive git reset action (requires explicit confirmation)
        $actions += [PSCustomObject]@{ id = 'git-force-reset'; label = 'Git: FORCE-RESET current branch to origin (destructive)'; cmd = '' }

    # Always available utilities
        $repoRoot = Join-Path $PSScriptRoot '..'
        $actions += [PSCustomObject]@{ id = 'scan-files'; label = 'Scan repo for common build/test files'; cmd = "Get-ChildItem -Path '$repoRoot' -Recurse -Force -ErrorAction SilentlyContinue | Where-Object Name -in @('package.json','pyproject.toml','requirements.txt','go.mod','Dockerfile','README.md') | Select-Object FullName | Format-Table -AutoSize" }
        $actions += [PSCustomObject]@{ id = 'open-copilot-instructions'; label = 'Open .github/copilot-instructions.md (if present)'; cmd = "if (Test-Path (Join-Path '$repoRoot' '.github/copilot-instructions.md')) { code (Join-Path '$repoRoot' '.github/copilot-instructions.md') } else { Write-Host 'No .github/copilot-instructions.md found' -ForegroundColor Yellow }" }
        $actions += [PSCustomObject]@{ id = 'custom'; label = 'Run a custom command'; cmd = '' }
        $actions += [PSCustomObject]@{ id = 'exit'; label = 'Exit'; cmd = '' }

    return $actions
}

function Show-Menu($actions) {
    Clear-Host
    Write-Host "Repository quick-actions (interactive)" -ForegroundColor Green
    Write-Host "Detected:"
    for ($i=0; $i -lt $actions.Count; $i++) {
        $idx = $i + 1
        Write-Host "[$idx] $($actions[$i].label)"
    }
    Write-Host "`nChoose a number and press Enter:`n"
}

function Pause { Write-Host "Press Enter to continue..."; [void][System.Console]::ReadLine() }

# Main loop
$actions = Detect-Actions

# If an action id was provided as a script parameter, run it and exit.
if ($Action) {
    $found = $actions | Where-Object { $_.id -eq $Action }
    if (-not $found) {
        Write-Host "Action id '$Action' not found. Available actions:" -ForegroundColor Red
        $actions | ForEach-Object { Write-Host " - $($_.id) : $($_.label)" }
        exit 2
    }

    $sel = $found[0]
    switch ($sel.id) {
        'repair-node' {
            if ($NonInteractive) { Run-Command $sel.cmd (Join-Path $PSScriptRoot '..') } else { Confirm-And-Run $sel.cmd 'Repair Node modules? This will REMOVE node_modules and reinstall (y/N)'}
        }
        'recreate-venv' {
            if ($NonInteractive) { Run-Command $sel.cmd (Join-Path $PSScriptRoot '..') } else { Confirm-And-Run $sel.cmd 'Recreate Python venv and install dependencies? (y/N)'}
        }
        'git-fetch-prune' {
            if ($NonInteractive) { Run-Command $sel.cmd (Join-Path $PSScriptRoot '..') } else { Confirm-And-Run $sel.cmd 'Run git fetch --all --prune and show status? (y/N)'}
        }
        'winget-upgrade-all' {
            if ($NonInteractive) { Run-Command $sel.cmd (Join-Path $PSScriptRoot '..') } else { Confirm-And-Run $sel.cmd 'Upgrade all winget-upgradable packages? This will modify installed programs (y/N)'}
        }
        'git-force-reset' {
            Force-GitReset -NonInteractive:$NonInteractive
        }
        'custom' {
            $cmd = Read-Host -Prompt 'Enter custom PowerShell command to run'
            if ($cmd) { Run-Command $cmd (Join-Path $PSScriptRoot '..') }
        }
        default {
            if (-not [string]::IsNullOrWhiteSpace($sel.cmd)) { Run-Command $sel.cmd (Join-Path $PSScriptRoot '..') }
            else { Write-Host "No command configured for this action" -ForegroundColor Yellow }
        }
    }

    exit 0
}

# Interactive menu loop
while ($true) {
    Show-Menu $actions
    $choice = Read-Host -Prompt 'Selection'
    if (-not [int]::TryParse($choice, [ref]$null)) {
        Write-Host "Invalid selection" -ForegroundColor Red
        Pause
        continue
    }
    $index = [int]$choice - 1
    if ($index -lt 0 -or $index -ge $actions.Count) {
        Write-Host "Out of range" -ForegroundColor Red
        Pause
        continue
    }

    $sel = $actions[$index]
    switch ($sel.id) {
        'custom' {
            $cmd = Read-Host -Prompt 'Enter custom PowerShell command to run'
            if ($cmd) { Run-Command $cmd (Join-Path $PSScriptRoot '..') }
        }
        'repair-node' {
            Confirm-And-Run $sel.cmd 'Repair Node modules? This will REMOVE node_modules and reinstall (y/N)'
        }
        'recreate-venv' {
            Confirm-And-Run $sel.cmd 'Recreate Python venv and install dependencies? (y/N)'
        }
        'git-fetch-prune' {
            Confirm-And-Run $sel.cmd 'Run git fetch --all --prune and show status? (y/N)'
        }
        'winget-upgrade-all' {
            Confirm-And-Run $sel.cmd 'Upgrade all winget-upgradable packages? This will modify installed programs (y/N)'
        }
        'git-force-reset' {
            Force-GitReset
        }
        'exit' { break }
        default {
            if (-not [string]::IsNullOrWhiteSpace($sel.cmd)) { Run-Command $sel.cmd (Join-Path $PSScriptRoot '..') }
            else { Write-Host "No command configured for this action" -ForegroundColor Yellow; Pause }
        }
    }
}

Write-Host "Goodbye." -ForegroundColor Green
