@echo off
REM Build KONTRAK APK for Android (Windows)
REM Usage: build_apk.bat

echo ==========================================
echo Building KONTRAK APK for Android
echo ==========================================
echo.

REM Set your environment variables here (or set them in system environment)
set SUPABASE_URL=%SUPABASE_URL%
if "%SUPABASE_URL%"=="" set SUPABASE_URL=https://YOUR-PROJECT.supabase.co

set SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
if "%SUPABASE_ANON_KEY%"=="" set SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY

set API_BASE_URL=%API_BASE_URL%
if "%API_BASE_URL%"=="" set API_BASE_URL=https://kontrakapi.onrender.com

echo Configuration:
echo   SUPABASE_URL: %SUPABASE_URL%
echo   API_BASE_URL: %API_BASE_URL%
echo.

REM Clean previous builds
echo Cleaning previous builds...
call flutter clean
call flutter pub get

REM Build APK release
echo.
echo Building APK release...
call flutter build apk --release --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY% --dart-define=API_BASE_URL=%API_BASE_URL%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo Build successful!
    echo ==========================================
    echo.
    echo APK location:
    echo   build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo To install on Android device:
    echo 1. Copy APK to your Android phone
    echo 2. Enable "Install from Unknown Sources"
    echo 3. Open APK file and install
    echo.
) else (
    echo.
    echo ==========================================
    echo Build failed!
    echo ==========================================
    echo Check errors above and try again.
    exit /b 1
)

pause
