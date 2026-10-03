@echo off
:: Windows PC Setup Launcher
:: Double-click this file to run the setup

echo Starting PC Setup Script...
echo.

:: Run PowerShell script with execution policy bypass
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

pause
