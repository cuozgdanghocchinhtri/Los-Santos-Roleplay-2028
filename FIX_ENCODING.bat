@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0FIX_ENCODING.ps1" -ProjectRoot "."
pause
