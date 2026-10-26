@echo off
setlocal enabledelayedexpansion

:: Determine project root directory from batch file location
set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

echo ========================================================
echo AirSense — AI Environmental Intelligence System
echo Safe Process Shutdown System
echo ========================================================
echo.

set "STOPPED_COUNT=0"

:: 1. Terminate FastAPI backend process by saved PID
if exist "%ROOT_DIR%runtime\fastapi.pid" (
    set /p FASTAPI_PID=<"%ROOT_DIR%runtime\fastapi.pid"
    if defined FASTAPI_PID (
        echo [Stopping] Terminating FastAPI Backend process [PID: !FASTAPI_PID!]...
        taskkill /F /PID !FASTAPI_PID! /T >nul 2>&1
        if !errorlevel! equ 0 (
            echo           FastAPI process stopped successfully.
            set /a STOPPED_COUNT+=1
        ) else (
            echo           FastAPI process was already terminated or inactive.
        )
    )
    del "%ROOT_DIR%runtime\fastapi.pid" >nul 2>&1
) else (
    echo [FastAPI]  No runtime\fastapi.pid found. Skipping.
)

:: 2. Terminate React + Vite frontend process by saved PID
if exist "%ROOT_DIR%runtime\vite.pid" (
    set /p VITE_PID=<"%ROOT_DIR%runtime\vite.pid"
    if defined VITE_PID (
        echo [Stopping] Terminating React Vite Frontend process [PID: !VITE_PID!]...
        taskkill /F /PID !VITE_PID! /T >nul 2>&1
        if !errorlevel! equ 0 (
            echo           React Vite process stopped successfully.
            set /a STOPPED_COUNT+=1
        ) else (
            echo           React Vite process was already terminated or inactive.
        )
    )
    del "%ROOT_DIR%runtime\vite.pid" >nul 2>&1
) else (
    echo [React UI] No runtime\vite.pid found. Skipping.
)

echo.
echo ========================================================
echo SHUTDOWN COMPLETE:
echo   - Only project-specific tracked processes were terminated.
echo   - No unrelated python.exe or Node processes were affected.
echo   - Runtime PID files cleaned.
echo ========================================================
echo.
