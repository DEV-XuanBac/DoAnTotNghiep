@echo off
setlocal

cd /d "%~dp0"

echo Starting HSK admin dashboard on Chrome...
echo Project: %cd%
echo.

flutter run -d chrome --target lib/admin/admin_web_main.dart
set EXITCODE=%ERRORLEVEL%

if not %EXITCODE%==0 (
  echo.
  echo [Error] Flutter exited with code %EXITCODE%.
  echo - Kiem tra da cai Flutter va Chrome chua.
  echo - Chay trong thu muc project: %cd%
  pause
  exit /b %EXITCODE%
)

endlocal
