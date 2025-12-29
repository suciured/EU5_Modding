Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Sync_AuthorityLedger.ps1
# - Reads destination from Mod Output.txt
# - Validates destination looks like an EU/Paradox mod folder
# - Shows file counts before/after
# - Empties destination, then copies Authority Ledger exactly
# ------------------------------------------------------------

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$MOD_OUTPUT_FILE = Join-Path $SCRIPT_DIR "Mod Output.txt"

# Fixed source (Authority Ledger in GitHub KB)
$SRC = "C:\Users\jason\OneDrive\Documents\GitHub\EU5_KB\Authority Ledger"

function Count-Files([string]$Path) : int {
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    return (Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
}

function Count-Dirs([string]$Path) : int {
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    return (Get-ChildItem -LiteralPath $Path -Recurse -Directory -Force -ErrorAction SilentlyContinue | Measure-Object).Count
}

function Is-Probably-ParadoxModFolder([string]$Path) : bool {
    # We do a "looks like" check:
    # - Common Paradox mod folders usually contain descriptor.mod OR .mod metadata,
    #   OR contain common top-level folders like "common", "localization", "gfx", etc.
    # This is conservative: it warns/blocks obvious wrong targets (e.g. Documents root).
    $descriptor = Join-Path $Path "descriptor.mod"
    if (Test-Path -LiteralPath $descriptor) { return $true }

    $commonMarkers = @("common","localization","gfx","interface","events","missions","history","map_data","gui")
    foreach ($m in $commonMarkers) {
        if (Test-Path -LiteralPath (Join-Path $Path $m)) { return $true }
    }

    return $false
}

# --- Validate inputs -----------------------------------------

if (-not (Test-Path -LiteralPath $MOD_OUTPUT_FILE)) {
    Write-Error "Mod Output.txt not found in: $SCRIPT_DIR"
    exit 1
}

if (-not (Test-Path -LiteralPath $SRC)) {
    Write-Error "Source folder not found: $SRC"
    exit 1
}

# --- Read destination from Mod Output.txt ---------------------

$DST = (Get-Content -LiteralPath $MOD_OUTPUT_FILE -Raw).Trim()

if ([string]::IsNullOrWhiteSpace($DST)) {
    Write-Error "Mod Output.txt is empty. Put the full destination folder path on one line."
    exit 1
}

# Create destination folder if needed
if (-not (Test-Path -LiteralPath $DST)) {
    New-Item -ItemType Directory -Path $DST -Force | Out-Null
}

# --- (4) Validate destination is probably a Paradox mod folder --

# Hard safety: block dangerous targets (root drive, user profile, Documents, etc.)
$badTargets = @("C:\", "$env:USERPROFILE", "$env:USERPROFILE\Documents")
foreach ($bt in $badTargets) {
    if ($DST.TrimEnd('\') -ieq $bt.TrimEnd('\')) {
        Write-Error "Refusing to wipe a high-risk folder target: $DST"
        exit 1
    }
}

# "Probably mod folder" check
if (-not (Is-Probably-ParadoxModFolder $DST)) {
    Write-Error @"
Destination does not look like a Paradox/EU mod folder (no descriptor.mod and no common mod folders found):
  $DST

Fix Mod Output.txt to point at the correct mod folder, e.g.:
  ...\Paradox Interactive\Europa Universalis V\mod\Authority Ledger
"@
    exit 1
}

# --- (2) Counts before ----------------------------------------

$dstFilesBefore = Count-Files $DST
$dstDirsBefore  = Count-Dirs  $DST
$srcFiles       = Count-Files $SRC
$srcDirs        = Count-Dirs  $SRC

Write-Host "PRE:"
Write-Host "  SRC files: $srcFiles   dirs: $srcDirs"
Write-Host "  DST files: $dstFilesBefore   dirs: $dstDirsBefore"
Write-Host ""

# --- Empty destination ----------------------------------------

Get-ChildItem -LiteralPath $DST -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction Stop

# --- Copy ------------------------------------------------------

Copy-Item -LiteralPath (Join-Path $SRC "*") `
          -Destination $DST `
          -Recurse `
          -Force `
          -ErrorAction Stop

# --- Counts after ---------------------------------------------

$dstFilesAfter = Count-Files $DST
$dstDirsAfter  = Count-Dirs  $DST

Write-Host "POST:"
Write-Host "  DST files: $dstFilesAfter   dirs: $dstDirsAfter"
Write-Host ""
Write-Host "OK: Synced Authority Ledger"
Write-Host "FROM: $SRC"
Write-Host "TO:   $DST"
