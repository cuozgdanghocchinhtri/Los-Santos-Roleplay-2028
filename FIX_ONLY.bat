@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0FIX_PIZZA_PROGRESS.ps1" -ProjectRoot "."
pause
