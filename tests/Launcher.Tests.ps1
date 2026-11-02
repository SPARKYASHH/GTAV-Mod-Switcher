#Requires -Version 5.1
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$exe=Join-Path $root 'GTA V Mod Switcher.exe'
$bytes=[IO.File]::ReadAllBytes($exe)
$pe=[BitConverter]::ToInt32($bytes,0x3c)
$subsystem=[BitConverter]::ToUInt16($bytes,$pe+24+68)
if($subsystem -ne 2){throw 'Launcher must be a Windows GUI executable, not a console executable.'}
$process=Start-Process -FilePath $exe -ArgumentList '--self-test' -PassThru -Wait
if($process.ExitCode -ne 0){throw 'Hidden launcher self-test failed.'}
# A broken package must fail clearly and return nonzero, without opening a modal test dialog.
$worker=Join-Path $root 'Launch-Worker.ps1'
$held=$worker+'.test-hold'
[IO.File]::Move($worker,$held)
try{
    $process=Start-Process -FilePath $exe -ArgumentList '--self-test' -PassThru -Wait
    if($process.ExitCode -eq 0){throw 'Launcher ignored a missing worker file.'}
}finally{[IO.File]::Move($held,$worker)}
# Shortcut creation is checked in a temporary directory; the real desktop is untouched.
$desktop=Join-Path ([IO.Path]::GetTempPath()) ('Sparkyashh-shortcut-test-'+[Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($desktop)
try{
    & (Join-Path $root 'Create-DesktopShortcut.ps1') -DesktopPath $desktop
    $shell=New-Object -ComObject WScript.Shell
    $link=$shell.CreateShortcut((Join-Path $desktop 'GTA V Mod Switcher by SPARKYASHH.lnk'))
    if($link.TargetPath -ine $exe){throw 'Desktop shortcut must point to the GUI EXE.'}
}finally{Remove-Item -LiteralPath $desktop -Recurse -Force}
Write-Host 'PASS: GUI executable, hidden workers, isolated checks, missing-file failure, EXE desktop shortcut'
