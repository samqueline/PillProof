@echo off
title Starting Pill Proof...
echo ========================================================
echo   Launching Pill Proof Application
echo ========================================================
echo.

echo 1. Launching Node.js Backend Server (http://localhost:5000)...
start "Pill Proof Backend API" cmd /k "cd /d "%~dp0backend" && npm run dev"

echo Waiting 3 seconds for backend to start...
timeout /t 3 /nobreak >nul

echo 2. Launching Flutter Frontend (Google Chrome)...
start "Pill Proof Flutter App" cmd /k "cd /d "%~dp0frontend" && flutter run -d chrome"

echo.
echo ========================================================
echo   Both Backend and Frontend have been started!
echo   You can close this window now.
echo ========================================================
pause

