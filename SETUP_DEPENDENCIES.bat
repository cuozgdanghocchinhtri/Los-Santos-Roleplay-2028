@echo off
cd /d "%~dp0"
title LS:RP - Setup Dependencies
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\setup_dependencies.ps1"
if errorlevel 1 (
    echo.
    echo [FAILED] Khong cai duoc dependencies.
    pause
    exit /b 1
)
echo.
echo [OK] Dependencies da san sang.
pause
