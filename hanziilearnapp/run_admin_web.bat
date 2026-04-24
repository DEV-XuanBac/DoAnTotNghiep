@echo off
setlocal

cd /d "%~dp0"

echo Starting HSK admin upload web on Chrome...
flutter run -d chrome --target lib/admin/hsk_exam_upload_web_main.dart

endlocal
