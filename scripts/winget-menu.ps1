<#
  scripts/winget-menu.ps1
  Interactive Winget manager: list installed packages, inspect, upgrade, uninstall, or search & install.

  Usage:
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\winget-menu.ps1

  Notes:
  - Requires Windows with winget available in PATH.
  - Uses JSON output from Winget (winget >= 1.2+). If your winget version doesn't support `--output json`, the script will fall back to raw text listing.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Run-Command {
    param(
        [string]$Command,
        [string]$WorkingDir = $PSScriptRoot
    )

    Write-Host "=> $Command" -ForegroundColor Cyan
    Push-Location $WorkingDir -ErrorAction SilentlyContinue
    try {
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
    } finally {
        Pop-Location -ErrorAction SilentlyContinue
    }

    Write-Host "`nPress Enter to continue..."; [void][System.Console]::ReadLine()
}

function Get-WingetListJson() {
    try {
        $json = winget list --source winget --output json 2>$null
        $lastVar = Get-Variable -Name 'LASTEXITCODE' -ErrorAction SilentlyContinue
        if (($lastVar -and $lastVar.Value -ne 0) -or -not $json) { return $null }
        return $json | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Show-Packages($pkgs) {
    Clear-Host
    Write-Host "Installed packages (winget)" -ForegroundColor Green
    $i = 1
    foreach ($p in $pkgs) {
        $avail = if ($p.AvailableVersion) { " -> $($p.AvailableVersion)" } else { "" }
        Write-Host "[$i] $($p.Name) ($($p.Id)) — $($p.Version)$avail"
        $i++
    }
}

function Show-Menu($count) {
    Write-Host "`nActions:`n" -ForegroundColor Cyan
    Write-Host "0  Refresh list"
    Write-Host "s  Search and install a package"
    Write-Host "q  Quit"
    Write-Host "Or enter package number to manage that package (upgrade/uninstall/details).`n"
}

function Manage-Package($pkg) {
    while ($true) {
        Clear-Host
        Write-Host "Package: $($pkg.Name) ($($pkg.Id))" -ForegroundColor Yellow
        Write-Host "Installed: $($pkg.Version)"
        if ($pkg.AvailableVersion) { Write-Host "Available: $($pkg.AvailableVersion)" -ForegroundColor Green }
        Write-Host "`nActions:"
        Write-Host "1) Upgrade"
        Write-Host "2) Uninstall"
        Write-Host "3) Show full info"
        Write-Host "b) Back to list"
        $choice = Read-Host -Prompt 'Selection'
        switch ($choice) {
            '1' {
                Run-Command "winget upgrade --id `"$($pkg.Id)`" --accept-package-agreements --accept-source-agreements"
            }
            '2' {
                Run-Command "winget uninstall --id `"$($pkg.Id)`" --accept-package-agreements --accept-source-agreements"
            }
            '3' {
                Run-Command "winget show --id `"$($pkg.Id)`""
            }
            'b' { break }
            default { Write-Host "Invalid selection" -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

function Search-And-Install() {
    $q = Read-Host -Prompt 'Search term (package name or id)'
    if (-not $q) { return }
    $out = winget search --name "$q" --output json 2>$null
    if (-not $out) { Write-Host "No results or winget search not supported on this version." -ForegroundColor Yellow; return }
    $results = $out | ConvertFrom-Json
    if (-not $results) { Write-Host "No results." -ForegroundColor Yellow; return }
    Clear-Host
    for ($i=0; $i -lt $results.Count; $i++) {
        $r = $results[$i]
        Write-Host "[$($i+1)] $($r.Name) ($($r.Id)) — $($r.Version) : $($r.Source)
"
    }
    $sel = Read-Host -Prompt 'Choose number to install or blank to cancel'
    if (-not [int]::TryParse($sel, [ref]$null)) { return }
    $idx = [int]$sel - 1
    if ($idx -lt 0 -or $idx -ge $results.Count) { Write-Host "Out of range" -ForegroundColor Red; return }
    $pkg = $results[$idx]
    Run-Command "winget install --id `"$($pkg.Id)`" --accept-package-agreements --accept-source-agreements"
}

# Main loop
while ($true) {
    $list = Get-WingetListJson
    if ($null -eq $list) {
        Write-Host "winget list JSON not available — falling back to raw text output." -ForegroundColor Yellow
        Run-Command 'winget list'
        break
    }

    Show-Packages $list
    Show-Menu $list.Count
    $choice = Read-Host -Prompt 'Selection'
    if ($choice -eq 'q') { break }
    if ($choice -eq 's') { Search-And-Install; continue }
    if ($choice -eq '0') { continue }
    if (-not [int]::TryParse($choice, [ref]$null)) { Write-Host "Invalid selection" -ForegroundColor Red; Start-Sleep -Seconds 1; continue }
    $idx = [int]$choice - 1
    if ($idx -lt 0 -or $idx -ge $list.Count) { Write-Host "Out of range" -ForegroundColor Red; Start-Sleep -Seconds 1; continue }
    $pkg = $list[$idx]
    Manage-Package $pkg
}

Write-Host "Exiting Winget manager." -ForegroundColor Green
