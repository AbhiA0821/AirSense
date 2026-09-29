@echo off
setlocal enabledelayedexpansion

:: Determine project root directory from batch file location
set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

echo ========================================================
echo AI-Powered Environmental Intelligence System
echo Milestone 3 Unified Startup System
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
set "PYTHONPATH=%ROOT_DIR%backend;%PYTHONPATH%"

echo.
echo [1/3] Starting FastAPI Backend (Port 8000)...
echo Backend URL: http://127.0.0.1:8000
echo Swagger API: http://127.0.0.1:8000/docs
powershell -NoProfile -ExecutionPolicy Bypass -Command "(Start-Process -FilePath 'cmd.exe' -ArgumentList '/k title FastAPI Backend (Port 8000) && %PYTHON_CMD% -m uvicorn backend.main:app --host 127.0.0.1 --port 8000' -WorkingDirectory '%ROOT_DIR%' -PassThru).Id | Out-File -FilePath '%ROOT_DIR%runtime\fastapi.pid' -Encoding ASCII"

echo Waiting for FastAPI backend to initialize and become ready...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ready = $false; for ($i=1; $i -le 40; $i++) { try { $res = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/docs' -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop; if ($res.StatusCode -eq 200) { $ready = $true; break; } } catch {} Start-Sleep -Seconds 1 } if ($ready) { Write-Host 'FastAPI backend is fully ready!' } else { Write-Host 'FastAPI readiness check continuing...' }"

echo.
echo [2/3] Starting Flask Milestone 2 Dashboard (Port 8080)...
echo Flask URL: http://127.0.0.1:8080
powershell -NoProfile -ExecutionPolicy Bypass -Command "(Start-Process -FilePath 'cmd.exe' -ArgumentList '/k title Flask M2 Dashboard (Port 8080) && %PYTHON_CMD% frontend/app.py' -WorkingDirectory '%ROOT_DIR%' -PassThru).Id | Out-File -FilePath '%ROOT_DIR%runtime\flask.pid' -Encoding ASCII"

echo Waiting for Flask frontend to initialize and become ready...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ready = $false; for ($i=1; $i -le 20; $i++) { try { $res = Invoke-WebRequest -Uri 'http://127.0.0.1:8080' -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop; if ($res.StatusCode -eq 200) { $ready = $true; break; } } catch {} Start-Sleep -Seconds 1 } if ($ready) { Write-Host 'Flask frontend is fully ready!' } else { Write-Host 'Flask readiness check continuing...' }"

echo.
echo [3/3] Starting Flutter Web Development Console (Chrome)...
echo Target: Chrome Browser Development UI
powershell -NoProfile -ExecutionPolicy Bypass -Command "(Start-Process -FilePath 'cmd.exe' -ArgumentList '/k title Flutter Chrome UI && flutter run -d chrome' -WorkingDirectory '%ROOT_DIR%flutter_app' -PassThru).Id | Out-File -FilePath '%ROOT_DIR%runtime\flutter.pid' -Encoding ASCII"

echo.
echo ========================================================
echo ALL SUBSYSTEMS LAUNCHED WITH PID TRACKING:
echo   FastAPI PID file: runtime\fastapi.pid
echo   Flask PID file:   runtime\flask.pid
echo   Flutter PID file: runtime\flutter.pid
echo.
echo Services:
echo   - FastAPI Backend:       http://127.0.0.1:8000
echo   - Flask M2 Dashboard:    http://127.0.0.1:8080
echo   - Flutter AI Console:    Launching in Chrome
echo ========================================================
echo.
echo To cleanly stop only these project services, run: stop.bat
echo.
pause
