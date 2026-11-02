@echo off
setlocal
rem Run isolated Windows tests before allowing operations on the user's game.
echo GTA V Mod Switcher by SPARKYASHH - checking this preview build...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tests\Core.Tests.ps1"
if errorlevel 1 goto failure
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0ModSwitch.ps1" -SmokeTest
if errorlevel 1 goto failure
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0ModSwitch.ps1"
if errorlevel 1 goto failure
exit /b 0
:failure
echo.
echo Check failed or the application could not start. No game operation was started by this launcher after a failed check.
echo Keep all package files together. Copy this error text for support.
pause
exit /b 1
