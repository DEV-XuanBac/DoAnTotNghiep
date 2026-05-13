@echo off
REM Chạy auto-fix lint + format đồng bộ cho toàn project.
REM Dùng: tool\format.bat
setlocal
cd /d "%~dp0\.."
echo == dart fix --apply ==
call dart fix --apply
if errorlevel 1 goto :err
echo == dart format --line-length=100 . ==
call dart format --line-length=100 .
if errorlevel 1 goto :err
echo == flutter analyze ==
call flutter analyze
exit /b %errorlevel%
:err
echo [format.bat] Lỗi khi chạy auto-fix/format.
exit /b 1
