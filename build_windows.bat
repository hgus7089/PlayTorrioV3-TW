@echo off
chcp 65001 >nul
setlocal
echo ==========================================
echo PlayTorrio V3 繁體中文版 - Windows 建置
echo ==========================================
where flutter >nul 2>nul
if errorlevel 1 (
  echo.
  echo 找不到 Flutter。請先安裝 Flutter SDK。
  echo https://docs.flutter.dev/get-started/install/windows
  pause
  exit /b 1
)
flutter --version
echo.
echo [1/3] 取得套件...
flutter pub get
if errorlevel 1 goto :fail
echo.
echo [2/3] 建置 Windows Release...
flutter build windows --release
if errorlevel 1 goto :fail
echo.
echo [3/3] 建置完成！
echo 執行檔位於：
echo build\windows\x64\runner\Release\playtorrio.exe
echo.
pause
exit /b 0
:fail
echo.
echo 建置失敗，請把上面的錯誤訊息貼給 ChatGPT，我可以幫你處理。
pause
exit /b 1
