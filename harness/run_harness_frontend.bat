@echo off
setlocal

set "HARNESS_DIR=%~dp0"
set "BACKEND_URL=http://127.0.0.1:8765"
set "FRONTEND_URL=http://127.0.0.1:5173"
set "FRONTEND_HOST=127.0.0.1"

if not "%HARNESS_BACKEND_URL%"=="" set "BACKEND_URL=%HARNESS_BACKEND_URL%"
if not "%HARNESS_FRONTEND_URL%"=="" set "FRONTEND_URL=%HARNESS_FRONTEND_URL%"
if not "%HARNESS_FRONTEND_HOST%"=="" set "FRONTEND_HOST=%HARNESS_FRONTEND_HOST%"

pushd "%HARNESS_DIR%" || exit /b 1

where npm >nul 2>nul
if errorlevel 1 (
  echo npm was not found. Install Node.js 20+ first.
  popd
  exit /b 1
)

set "BACKEND_COMMAND=python -m backend.server"
if exist ".venv\Scripts\python.exe" set "BACKEND_COMMAND=.venv\Scripts\python.exe -m backend.server"

if not exist "frontend\node_modules" (
  echo frontend\node_modules was not found. Installing frontend dependencies...
  pushd "frontend" || exit /b 1
  call npm install
  if errorlevel 1 (
    popd
    popd
    exit /b 1
  )
  popd
)

call :UrlReady "%BACKEND_URL%/api/tasks"
if errorlevel 1 (
  echo Starting backend at %BACKEND_URL%...
  start "Harness Backend" /D "%HARNESS_DIR%" cmd /k "%BACKEND_COMMAND%"
  call :WaitForUrl "%BACKEND_URL%/api/tasks" "Backend" 60
  if errorlevel 1 (
    popd
    exit /b 1
  )
) else (
  echo Backend is already running at %BACKEND_URL%.
)

call :UrlReady "%FRONTEND_URL%"
if errorlevel 1 (
  echo Starting frontend at %FRONTEND_URL%...
  start "Harness Frontend" /D "%HARNESS_DIR%frontend" cmd /k "npm run dev -- --host %FRONTEND_HOST%"
  call :WaitForUrl "%FRONTEND_URL%" "Frontend" 60
  if errorlevel 1 (
    popd
    exit /b 1
  )
) else (
  echo Frontend is already running at %FRONTEND_URL%.
)

start "" "%FRONTEND_URL%"

echo.
echo Harness dashboard is ready.
echo Backend:  %BACKEND_URL%
echo Frontend: %FRONTEND_URL%

popd
exit /b 0

:UrlReady
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri '%~1' -TimeoutSec 2; if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500) { exit 0 }; exit 1 } catch { exit 1 }"
exit /b %ERRORLEVEL%

:WaitForUrl
set "WAIT_URL=%~1"
set "WAIT_NAME=%~2"
set "WAIT_MAX=%~3"
set /a WAIT_COUNT=0

:WaitForUrlLoop
call :UrlReady "%WAIT_URL%"
if not errorlevel 1 exit /b 0

set /a WAIT_COUNT+=1
if %WAIT_COUNT% GEQ %WAIT_MAX% (
  echo %WAIT_NAME% did not become ready at %WAIT_URL% within %WAIT_MAX%s.
  exit /b 1
)

timeout /t 1 /nobreak >nul
goto :WaitForUrlLoop
