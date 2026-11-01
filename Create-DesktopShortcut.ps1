#Requires -Version 5.1
$ErrorActionPreference='Stop'
try {
    $desktop=[Environment]::GetFolderPath('DesktopDirectory')
    $shortcutPath=Join-Path $desktop 'GTA V Mod Switcher by SPARKYASHH.lnk'
    if(Test-Path -LiteralPath $shortcutPath){throw 'Ярлык с таким именем уже есть. Удалите или переименуйте его, если хотите создать новый.'}
    $iconPath=Join-Path $PSScriptRoot 'assets/app.ico'
    $target=Join-Path $PSScriptRoot 'START.cmd'
    if(-not (Test-Path -LiteralPath $iconPath) -or -not (Test-Path -LiteralPath $target)){throw 'Распакуйте весь архив в постоянную папку перед созданием ярлыка.'}
    $shell=New-Object -ComObject WScript.Shell
    $shortcut=$shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath=$target
    $shortcut.WorkingDirectory=$PSScriptRoot
    $shortcut.IconLocation=$iconPath+',0'
    $shortcut.Description='GTA V Mod Switcher by SPARKYASHH'
    $shortcut.Save()
    Write-Host ('Ярлык создан: '+$shortcutPath)
    Write-Host 'Не переносите папку программы после создания ярлыка.'
} catch {Write-Host $_.Exception.Message -ForegroundColor Red;exit 1}
