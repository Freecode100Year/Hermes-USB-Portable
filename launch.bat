@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM Hermes Agent - Portable Launcher (Windows)
REM ============================================================================
REM Double-click this file to launch Hermes.
REM On first run, it downloads ~600MB of runtime files automatically.
REM All data stays in the "data\" folder - nothing touches the host computer.
REM ============================================================================

REM Resolve portable root (directory containing this script)
set "PORTABLE_ROOT=%~dp0"
set "PORTABLE_ROOT=%PORTABLE_ROOT:~0,-1%"

set "HERMES_HOME=%PORTABLE_ROOT%\data"
set "CACHE_DIR=%PORTABLE_ROOT%\.cache"
set "RUNTIME_DIR=%CACHE_DIR%\runtimes\windows-x64"
set "SRC_DIR=%PORTABLE_ROOT%\src"

REM ---------------------------------------------------------------------------
REM First-run setup
REM ---------------------------------------------------------------------------
if not exist "%RUNTIME_DIR%\ready.flag" (
    echo.
    echo ============================================
    echo    Hermes Portable - First Run Setup
    echo ============================================
    echo  This will download ~600MB of runtime files
    echo  for Windows x64. Please be patient.
    echo ============================================
    echo.
    powershell -ExecutionPolicy Bypass -File "%PORTABLE_ROOT%\scripts\setup-windows.ps1" -Root "%PORTABLE_ROOT%"
    if errorlevel 1 (
        echo.
        echo [ERROR] Setup failed. Please check your internet connection and try again.
        pause
        exit /b 1
    )
)

REM ---------------------------------------------------------------------------
REM Environment isolation - keep everything inside the portable folder
REM ---------------------------------------------------------------------------
set "VIRTUAL_ENV=%RUNTIME_DIR%\venv"
set "PATH=%VIRTUAL_ENV%\Scripts;%RUNTIME_DIR%\python;%RUNTIME_DIR%\python\Scripts;%RUNTIME_DIR%\node;%RUNTIME_DIR%\uv;%RUNTIME_DIR%\bin;%PATH%"
set "PYTHONNOUSERSITE=1"
set "PYTHONHOME="
set "PYTHONPATH="
set "UV_NO_CONFIG=1"
set "UV_PYTHON=%RUNTIME_DIR%\python\python.exe"
set "PLAYWRIGHT_BROWSERS_PATH=%RUNTIME_DIR%\playwright"
set "NODE_PATH=%RUNTIME_DIR%\node\node_modules"
set "NPM_CONFIG_PREFIX=%RUNTIME_DIR%\node"

REM Prevent Node from writing to host appdata
set "APPDATA=%PORTABLE_ROOT%\.cache\windows-appdata"
set "LOCALAPPDATA=%PORTABLE_ROOT%\.cache\windows-localappdata"

REM ---------------------------------------------------------------------------
REM Launch Hermes
REM ---------------------------------------------------------------------------
if not exist "%SRC_DIR%\hermes-agent" (
    echo [ERROR] Hermes source not found. Please delete .cache and try again.
    pause
    exit /b 1
)

cd /d "%SRC_DIR%\hermes-agent"

REM Strip "hermes" from the start of arguments if user typed "launch.bat hermes setup"
set "ARGS=%*"
if /I "%~1"=="hermes" (
    set "ARGS=%ARGS:~7%"
)

REM If no arguments given, auto-detect first-run vs chat
if "%ARGS%"=="" (
    REM Check if setup has been completed (look for API key in .env)
    set "SETUP_DONE=0"
    if exist "%HERMES_HOME%\.env" (
        findstr /R /C:"^[A-Z].*=" "%HERMES_HOME%\.env" >/dev/null 2>&1
        if not errorlevel 1 set "SETUP_DONE=1"
    )
    if "!SETUP_DONE!"=="0" (
        echo.
        echo [First run] No API key found. Starting setup wizard...
        echo.
        hermes setup
    ) else (
        hermes
    )
) else (
    hermes %ARGS%
)
exit /b