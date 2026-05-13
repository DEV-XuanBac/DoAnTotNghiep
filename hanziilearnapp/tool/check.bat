@echo off
REM Pipeline kiểm tra nhanh trước khi commit: analyze + test.
REM Dùng: tool\check.bat
setlocal
cd /d "%~dp0\.."
echo == flutter analyze ==
call flutter analyze
if errorlevel 1 goto :err
echo == flutter test ==
call flutter test
exit /b %errorlevel%
:err
echo [check.bat] flutter analyze báo lỗi - cần fix trước khi commit.
exit /b 1
