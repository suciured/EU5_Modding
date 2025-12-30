Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Sync_AuthorityLedger.ps1
# Source: Workspace\Mod\Authority Ledger
# Dest:   Paradox EUV mod\Authority Ledger
# Behavior:
#   - Print counts before / after wipe / after copy
#   - Wipe destination contents every run, then copy source exactly
# ------------------------------------------------------------

function Count-Tree([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ Files = 0; Dirs = 0 }
    }

    $files = (Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $dirs  = (Get-ChildItem -LiteralPath $Path -Recurse -Force -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
    return [pscustomobject]@{ Files = $files; Dirs = $dirs }
}

function Ensure-Dir([string]$p) {
    if (-not (Test-Path -LiteralPath $p)) {
        New-Item -ItemType Directory -Path $p -Force | Out-Null
    }
}

# --- Paths (FIXED) -------------------------------------------

$SRC = "C:\Users\jason\OneDrive\Documents\GitHub\EU5_Modding\Workspace\Mod\Authority Ledger"
$DST = "C:\Users\jason\OneDrive\Documents\Paradox Interactive\Europa Universalis V\mod\Authority Ledger"

# --- Validate source exists -----------------------------------

if (-not (Test-Path -LiteralPath $SRC)) {
    Write-Error "Source folder not found: $SRC"
    exit 1
}

# --- Counts (before) ------------------------------------------

$srcBefore = Count-Tree $SRC
$dstBefore = Count-Tree $DST

Write-Host "BEFORE:"
Write-Host "  SRC: $SRC"
Write-Host "       Files=$($srcBefore.Files)  Dirs=$($srcBefore.Dirs)"
Write-Host "  DST: $DST"
Write-Host "       Files=$($dstBefore.Files)  Dirs=$($dstBefore.Dirs)"
Write-Host ""

# --- Prepare destination --------------------------------------

Ensure-Dir $DST

# Wipe destination contents (keep root folder)
Get-ChildItem -LiteralPath $DST -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction Stop

$dstAfterWipe = Count-Tree $DST

Write-Host "AFTER WIPE:"
Write-Host "  DST: $DST"
Write-Host "       Files=$($dstAfterWipe.Files)  Dirs=$($dstAfterWipe.Dirs)"
Write-Host ""

# --- Copy ------------------------------------------------------

Copy-Item -LiteralPath (Join-Path $SRC "*") `
          -Destination $DST `
          -Recurse `
          -Force `
          -ErrorAction Stop

$dstAfterCopy = Count-Tree $DST

Write-Host "AFTER COPY:"
Write-Host "  DST: $DST"
Write-Host "       Files=$($dstAfterCopy.Files)  Dirs=$($dstAfterCopy.Dirs)"
Write-Host ""
Write-Host "OK: Synced Authority Ledger."
