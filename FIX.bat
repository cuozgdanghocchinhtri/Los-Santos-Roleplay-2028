@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0FIX_PIZZA_DUPLICATE.ps1" -ProjectRoot "."
pause
