@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-Launcher.ps1"
if errorlevel 1 (
 echo Build failed.
 pause
 exit /b 1
)
echo Launcher ready. Open app\GTA V Mod Switcher.exe for a console-free start.
pause
