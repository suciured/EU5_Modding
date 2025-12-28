@echo off
echo Syncing Authority Ledger...
powershell -ExecutionPolicy Bypass -File "%~dp0Sync_AuthorityLedger.ps1"
pause
