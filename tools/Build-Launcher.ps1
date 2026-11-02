#Requires -Version 5.1
$ErrorActionPreference='Stop'
$compiler=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
if(-not (Test-Path -LiteralPath $compiler)){$compiler=Join-Path $env:WINDIR 'Microsoft.NET/Framework/v4.0.30319/csc.exe'}
if(-not (Test-Path -LiteralPath $compiler)){throw 'Windows .NET Framework compiler was not found.'}
$project=Split-Path -Parent $PSScriptRoot
$app=Join-Path $project 'app'
$output=Join-Path $app 'GTA V Mod Switcher.exe'
$icon=Join-Path $app 'assets/app.ico'
$source=Join-Path $project 'src/Launcher.cs'
& $compiler /nologo /target:winexe /optimize+ /platform:anycpu /reference:System.Windows.Forms.dll "/win32icon:$icon" "/out:$output" $source
if($LASTEXITCODE -ne 0){throw "Launcher compilation failed ($LASTEXITCODE)."}
Write-Host "Built: $output"
