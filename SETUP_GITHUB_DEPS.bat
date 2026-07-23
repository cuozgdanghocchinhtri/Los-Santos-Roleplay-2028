@echo off
title LSRP - GitHub Dependency Setup
cd /d "%~dp0"

echo.
echo =============================================
echo  LSRP - DOWNLOAD DEPENDENCIES FROM GITHUB
echo =============================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SETUP_GITHUB_DEPS.ps1"

if errorlevel 1 (
    echo.
    echo [FAILED] Dependency setup bi loi.
    pause
    exit /b 1
)

echo.
echo [OK] Dependencies da cai xong.
pause
