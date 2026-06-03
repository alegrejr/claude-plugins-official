@echo off
if "%~1"=="" (
    echo Usage: check_delivery.bat "C:\path\to\delivery\folder"
    pause
    exit /b 1
)
powershell -ExecutionPolicy Bypass -File "%~dp0check_delivery.ps1" "%~1"
