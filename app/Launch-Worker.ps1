#Requires -Version 5.1
param([Parameter(Mandatory=$true)][ValidateSet('Tests','Smoke','App','Probe')][string]$Step)
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=New-Object Text.UTF8Encoding($false)
try {
    switch($Step){
        'Tests' { & (Join-Path $PSScriptRoot 'tests/Core.Tests.ps1') }
        'Smoke' { & (Join-Path $PSScriptRoot 'ModSwitch.ps1') -SmokeTest }
        'App'   { & (Join-Path $PSScriptRoot 'ModSwitch.ps1') }
        'Probe' {
            Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class ConsoleProbe { [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); }'
            if([ConsoleProbe]::GetConsoleWindow() -ne [IntPtr]::Zero){throw 'Hidden worker unexpectedly has a console window.'}
            Write-Output 'PASS: worker has no console window'
        }
    }
    exit 0
} catch {
    [Console]::Error.WriteLine($_.Exception.ToString())
    exit 1
}
