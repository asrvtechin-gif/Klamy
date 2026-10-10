@echo off
title Klamy Local AI Server
echo ========================================================
echo           Starting Klamy Local AI Server
echo ========================================================
echo.

set "FIREBASE_PROJECT_ID=klamy-8789e"
set "FIREBASE_DATABASE_URL=https://klamy-8789e-default-rtdb.firebaseio.com"
set "GOOGLE_APPLICATION_CREDENTIALS=%USERPROFILE%\.klamy\admin-sdk.json"

echo [1/3] Checking Firebase service account credentials...
if exist "%GOOGLE_APPLICATION_CREDENTIALS%" (
    echo     Firebase credentials found: %GOOGLE_APPLICATION_CREDENTIALS%
) else (
    echo     Warning: %GOOGLE_APPLICATION_CREDENTIALS% not found.
)

echo.
echo [2/3] Checking connected Android devices via ADB...
where adb >nul 2>nul
if %errorlevel% equ 0 (
    adb reverse tcp:8000 tcp:8000 >nul 2>nul
    if %errorlevel% equ 0 (
        echo     ADB reverse port 8000 successfully configured for connected phone!
        echo     Your phone can now connect directly via http://127.0.0.1:8000 (No tunnel needed over USB).
    ) else (
        echo     No USB phone connected for adb reverse (or multiple devices).
    )
) else (
    echo     ADB not found in PATH (skip adb reverse).
)

echo.
echo [3/3] Starting FastAPI gateway on 0.0.0.0:8000...
echo.
echo If using a phone via Cloudflare Tunnel, run in another window:
echo     cloudflared tunnel --url http://localhost:8000
echo.

cd /d "%~dp0"
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload

pause
