@echo off
echo Syncing Authority Ledger...

REM %~dp0 = directory this CMD is in (with trailing backslash)
powershell -ExecutionPolicy Bypass -File "%~dp0Sync_AuthorityLedger.ps1"

pause
