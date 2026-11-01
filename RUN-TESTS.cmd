@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tests\Core.Tests.ps1"
if errorlevel 1 goto failure
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0ModSwitch.ps1" -SmokeTest
if errorlevel 1 goto failure
echo All Windows tests passed.
pause
exit /b 0
:failure
echo TEST FAILED. Do not use this build with real mods yet.
pause
exit /b 1
