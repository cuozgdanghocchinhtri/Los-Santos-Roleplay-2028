@echo off
title LSRP Dependency Manager
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALL_DEPS.ps1"

if errorlevel 1 (
    echo.
    echo [FAILED] Xem loi o phia tren.
    pause
    exit /b 1
)

echo.
echo [OK] Hoan tat.
pause
