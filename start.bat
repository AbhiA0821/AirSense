@echo off
setlocal enabledelayedexpansion

:: Determine project root directory from batch file location
set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

echo ========================================================
echo AirSense — AI Environmental Intelligence System
echo Production Unified Startup (FastAPI + React Vite)
echo ========================================================
echo.

:: Ensure runtime tracking directory exists
if not exist "%ROOT_DIR%runtime" (
    mkdir "%ROOT_DIR%runtime"
)

:: Detect Python environment
if exist "%ROOT_DIR%backend\venv\Scripts\python.exe" (
    set "PYTHON_CMD=%ROOT_DIR%backend\venv\Scripts\python.exe"
    echo [Environment] Detected virtual environment: backend\venv
) else if exist "%ROOT_DIR%.venv\Scripts\python.exe" (
    set "PYTHON_CMD=%ROOT_DIR%.venv\Scripts\python.exe"
    echo [Environment] Detected virtual environment: .venv
) else if exist "%ROOT_DIR%venv\Scripts\python.exe" (
    set "PYTHON_CMD=%ROOT_DIR%venv\Scripts\python.exe"
    echo [Environment] Detected virtual environment: venv
) else (
    set "PYTHON_CMD=python"
    echo [Environment] Using system Python
)

:: Set PYTHONPATH to ensure backend imports resolve correctly
set "PYTHONPATH=%ROOT_DIR%backend;%ROOT_DIR%;%PYTHONPATH%"

echo.
echo [1/2] Starting FastAPI Backend (Port 8000)...
echo Backend URL: http://127.0.0.1:8000
echo Swagger API: http://127.0.0.1:8000/docs
powershell -NoProfile -ExecutionPolicy Bypass -Command "(Start-Process -FilePath 'cmd.exe' -ArgumentList '/k title AirSense FastAPI Backend (Port 8000) && %PYTHON_CMD% -m uvicorn backend.app_final:app --host 127.0.0.1 --port 8000' -WorkingDirectory '%ROOT_DIR%' -PassThru).Id | Out-File -FilePath '%ROOT_DIR%runtime\fastapi.pid' -Encoding ASCII"

echo Waiting for FastAPI backend to initialize and become ready...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ready = $false; for ($i=1; $i -le 40; $i++) { try { $res = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/docs' -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop; if ($res.StatusCode -eq 200) { $ready = $true; break; } } catch {} Start-Sleep -Seconds 1 } if ($ready) { Write-Host 'FastAPI backend is fully ready!' } else { Write-Host 'FastAPI readiness check continuing...' }"

echo.
echo [2/2] Starting React + Vite Frontend (Port 5173)...
echo Frontend URL: http://127.0.0.1:5173
powershell -NoProfile -ExecutionPolicy Bypass -Command "(Start-Process -FilePath 'cmd.exe' -ArgumentList '/k title AirSense React Frontend (Port 5173) && npm run dev -- --host 127.0.0.1 --port 5173' -WorkingDirectory '%ROOT_DIR%airsense-frontend' -PassThru).Id | Out-File -FilePath '%ROOT_DIR%runtime\vite.pid' -Encoding ASCII"

echo Waiting for React + Vite frontend to initialize and become ready...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ready = $false; for ($i=1; $i -le 30; $i++) { try { $res = Invoke-WebRequest -Uri 'http://127.0.0.1:5173' -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop; if ($res.StatusCode -eq 200) { $ready = $true; break; } } catch {} Start-Sleep -Seconds 1 } if ($ready) { Write-Host 'React + Vite frontend is fully ready!' } else { Write-Host 'Frontend readiness check continuing...' }"

echo.
echo ========================================================
echo ALL SUBSYSTEMS LAUNCHED WITH PID TRACKING:
echo   FastAPI PID file: runtime\fastapi.pid
echo   Vite UI PID file: runtime\vite.pid
echo.
echo Live Services:
echo   - React + Vite Web UI:   http://127.0.0.1:5173
echo   - FastAPI Backend API:   http://127.0.0.1:8000
echo   - Interactive API Docs:  http://127.0.0.1:8000/docs
echo ========================================================
echo.
echo To cleanly stop only these project services, run: stop.bat
echo.
pause
