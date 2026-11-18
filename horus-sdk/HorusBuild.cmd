@echo off
rem Horus build page: double-click. Opens the browser page of horus-build.mjs ui (build key, horus-game.json, APK / AAB /
rem Google Play / TestFlight, steps, % and Stop). The game: a folder dropped on this file, else the folder above this one
rem when it holds horus-game.json (the SDK copied to <game>\horus-sdk\), else the SDK's example. Close the window to stop.
setlocal
chcp 65001 >nul
where node >nul 2>nul
if errorlevel 1 (
  echo Chua co Node.js. Cai Node 18 tro len tu https://nodejs.org roi bam lai file nay.
  start "" https://nodejs.org/en/download
  pause
  exit /b 1
)
node -e "process.exit(+process.versions.node.split('.')[0] < 18 ? 1 : 0)"
if errorlevel 1 (
  echo Node.js qua cu. Cai Node 18 tro len tu https://nodejs.org roi bam lai file nay.
  pause
  exit /b 1
)
set "GAME=%~1"
if not defined GAME if exist "%~dp0..\horus-game.json" set "GAME=%~dp0.."
if not defined GAME (
  set "GAME=%~dp0example"
  echo Chua thay horus-game.json cua game: mo game thu "example". Keo tha thu muc game vao file nay de build game cua minh.
)
echo Game: %GAME%
echo Trang build mo tren trinh duyet. Dong cua so nay la tat trang.
node "%~dp0horus-build.mjs" ui "%GAME%"
pause
