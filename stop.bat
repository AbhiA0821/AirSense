@echo off
setlocal enabledelayedexpansion

:: Determine project root directory from batch file location
set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

echo ========================================================
echo AI-Powered Environmental Intelligence System
echo Milestone 3 Safe Process Shutdown System
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

:: 2. Terminate Flask M2 frontend process by saved PID
if exist "%ROOT_DIR%runtime\flask.pid" (
    set /p FLASK_PID=<"%ROOT_DIR%runtime\flask.pid"
    if defined FLASK_PID (
        echo [Stopping] Terminating Flask Frontend process [PID: !FLASK_PID!]...
        taskkill /F /PID !FLASK_PID! /T >nul 2>&1
        if !errorlevel! equ 0 (
            echo           Flask process stopped successfully.
            set /a STOPPED_COUNT+=1
        ) else (
            echo           Flask process was already terminated or inactive.
        )
    )
    del "%ROOT_DIR%runtime\flask.pid" >nul 2>&1
) else (
    echo [Flask]    No runtime\flask.pid found. Skipping.
)

:: 3. Terminate Flutter Chrome development process by saved PID
if exist "%ROOT_DIR%runtime\flutter.pid" (
    set /p FLUTTER_PID=<"%ROOT_DIR%runtime\flutter.pid"
    if defined FLUTTER_PID (
        echo [Stopping] Terminating Flutter Development process [PID: !FLUTTER_PID!]...
        taskkill /F /PID !FLUTTER_PID! /T >nul 2>&1
        if !errorlevel! equ 0 (
            echo           Flutter process stopped successfully.
            set /a STOPPED_COUNT+=1
        ) else (
            echo           Flutter process was already terminated or inactive.
        )
    )
    del "%ROOT_DIR%runtime\flutter.pid" >nul 2>&1
) else (
    echo [Flutter]  No runtime\flutter.pid found. Skipping.
)

echo.
echo ========================================================
echo SHUTDOWN COMPLETE:
echo   - Only project-specific tracked processes were terminated.
echo   - No unrelated python.exe or Chrome processes were affected.
echo   - Runtime PID files cleaned.
echo ========================================================
echo.
