#Requires -Version 5.1
param([string]$DesktopPath)
$ErrorActionPreference='Stop'
try {
    $desktop=if($DesktopPath){[IO.Path]::GetFullPath($DesktopPath)}else{[Environment]::GetFolderPath('DesktopDirectory')}
    $shortcutPath=Join-Path $desktop 'GTA V Mod Switcher by SPARKYASHH.lnk'
    $iconPath=Join-Path $PSScriptRoot 'assets/app.ico'
    $target=Join-Path $PSScriptRoot 'GTA V Mod Switcher.exe'
    if(-not (Test-Path -LiteralPath $iconPath) -or -not (Test-Path -LiteralPath $target)){throw 'Распакуйте весь архив в постоянную папку перед созданием ярлыка.'}
    $shell=New-Object -ComObject WScript.Shell
    $shortcut=$shell.CreateShortcut($shortcutPath)
    if((Test-Path -LiteralPath $shortcutPath) -and $shortcut.Description -ne 'GTA V Mod Switcher by SPARKYASHH'){throw 'Одноимённый ярлык создан другой программой. Переименуйте его перед созданием нового.'}
    $shortcut.TargetPath=$target
    $shortcut.WorkingDirectory=$PSScriptRoot
    $shortcut.IconLocation=$iconPath+',0'
    $shortcut.Description='GTA V Mod Switcher by SPARKYASHH'
    $shortcut.Save()
    Write-Host ('Ярлык создан или обновлён: '+$shortcutPath)
    Write-Host 'Не переносите папку программы после создания ярлыка.'
} catch {Write-Host $_.Exception.Message -ForegroundColor Red;exit 1}
