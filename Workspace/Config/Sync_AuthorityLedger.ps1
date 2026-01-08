Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

$SRC = "C:\Users\jason\OneDrive\Documents\GitHub\EU5_Modding\Workspace\Mod\More LR"
$DST = "C:\Users\jason\OneDrive\Documents\Paradox Interactive\Europa Universalis V\mod\More LR"

if (-not (Test-Path -LiteralPath $SRC)) {
    throw "Source folder not found: $SRC"
}

Ensure-Dir $DST

$srcBefore = Count-Tree $SRC
$dstBefore = Count-Tree $DST

Write-Host "BEFORE:"
Write-Host "  SRC: $SRC"
Write-Host "       Files=$($srcBefore.Files)  Dirs=$($srcBefore.Dirs)"
Write-Host "  DST: $DST"
Write-Host "       Files=$($dstBefore.Files)  Dirs=$($dstBefore.Dirs)"
Write-Host ""

# Use ROBOCOPY to mirror SRC -> DST (this effectively wipes + copies correctly)
# /MIR = mirror (adds + removes to match source)
# /R:0 /W:0 = no retries/waits
# /NFL /NDL /NP = quieter output
$cmd = @(
    "robocopy",
    "`"$SRC`"",
    "`"$DST`"",
    "/MIR",
    "/COPY:DAT",
    "/DCOPY:DAT",
    "/R:0",
    "/W:0",
    "/NFL",
    "/NDL",
    "/NP"
) -join " "

cmd /c $cmd | Out-Host

# Robocopy exit codes: 0-7 = success, >=8 = failure
$rc = $LASTEXITCODE
if ($rc -ge 8) {
    throw "ROBOCOPY failed with exit code $rc"
}

$dstAfterCopy = Count-Tree $DST

Write-Host ""
Write-Host "AFTER COPY:"
Write-Host "  DST: $DST"
Write-Host "       Files=$($dstAfterCopy.Files)  Dirs=$($dstAfterCopy.Dirs)"
Write-Host ""
Write-Host "OK: Synced Authority Ledger."
