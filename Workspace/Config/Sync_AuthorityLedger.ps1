# ============================================================
# Sync_AuthorityLedger.ps1
# Purpose: Sync Authority Ledger workspace to Mod Output target
# ============================================================

$ErrorActionPreference = "Stop"

# --- Paths ---
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceSource = Join-Path $ScriptRoot "Authority Ledger"
$ModOutputFile = Join-Path $ScriptRoot "Mod Output.txt"

# --- Validation ---
if (!(Test-Path $ModOutputFile)) {
    Write-Error "Mod Output.txt not found. Aborting."
}

$Destination = Get-Content $ModOutputFile | Select-Object -First 1

if ([string]::IsNullOrWhiteSpace($Destination)) {
    Write-Error "Mod Output.txt is empty. Aborting."
}

if (!(Test-Path $WorkspaceSource)) {
    Write-Error "Workspace source folder not found: $WorkspaceSource"
}

if (!(Test-Path $Destination)) {
    Write-Error "Destination path does not exist: $Destination"
}

# --- Safety Check ---
if ($Destination.Length -lt 10) {
    Write-Error "Destination path too short; unsafe to delete. Aborting."
}

Write-Host "Clearing destination: $Destination"
Get-ChildItem -Path $Destination -Force | Remove-Item -Recurse -Force

Write-Host "Copying from workspace to destination..."
Copy-Item -Path (Join-Path $WorkspaceSource "*") `
          -Destination $Destination `
          -Recurse `
          -Force

Write-Host "Authority Ledger sync completed successfully."
