# GTA V Mod Switcher by SPARKYASHH -- Windows PowerShell 5.1+
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-FullPath([string]$Path) {
    return [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}
function Test-Exists([string]$Path) { return Test-Path -LiteralPath $Path }
function Assert-PlainPath([string]$Path) {
    $current = Get-FullPath $Path
    while ($current) {
        if (Test-Exists $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Ссылка или junction в пути: $current" }
        }
        $parent = [IO.Path]::GetDirectoryName($current)
        if ($parent -eq $current) { break }; $current = $parent
    }
}
function Assert-Game([string]$GamePath) {
    if (-not [IO.Path]::IsPathRooted($GamePath)) { throw 'Выберите полный путь к папке GTA V.' }
    Assert-PlainPath $GamePath
    if (-not (([IO.File]::Exists((Join-Path $GamePath 'GTA5.exe'))) -or ([IO.File]::Exists((Join-Path $GamePath 'GTA5_Enhanced.exe'))))) {
        throw 'В выбранной папке нет GTA5.exe или GTA5_Enhanced.exe.'
    }
}
function Assert-ModName([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name) -or $Name -match '[\\/:*?"<>|]' -or $Name -match '[. ]$' -or $Name -eq '.' -or $Name -eq '..') { throw "Недопустимое имя: $Name" }
    $protected = @('update','x64','Redistributables','Installers','BattlEye','.egstore','Launcher','steam_api64.dll','steam_api.dll','bink2w64.dll','binkw64.dll','EOSSDK-Win64-Shipping.dll','GFSDK_ShadowLib.win64.dll','GFSDK_TXAA.win64.dll','GFSDK_TXAA_AlphaResolve.win64.dll','NvPmApi.Core.win64.dll','version.txt','common.rpf')
    if ($protected -contains $Name -or $Name -match '\.(exe|rpf)$' -or $Name -match '^x64[a-z]$') { throw "Защищённый игровой компонент: $Name" }
}
function Write-JsonSafe([string]$Path, $Value) {
    $temp = $Path + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
    $backup = $Path + '.previous'
    try {
        $bytes = [Text.UTF8Encoding]::new($true).GetBytes(($Value | ConvertTo-Json -Depth 12))
        $stream = [IO.File]::Open($temp, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        if (Test-Exists $Path) { [IO.File]::Replace($temp,$Path,$backup) }
        else { [IO.File]::Move($temp,$Path) }
    } finally { if (Test-Exists $temp) { [IO.File]::Delete($temp) } }
}
function Read-Json([string]$Path) {
    return ([IO.File]::ReadAllText($Path) | ConvertFrom-Json)
}
function Get-SwitchContext([string]$GamePath) {
    Assert-Game $GamePath
    $game = Get-FullPath $GamePath
    $parent = [IO.Path]::GetDirectoryName($game)
    if (-not $parent) { throw 'Корень диска не может быть папкой игры.' }
    $storage = Join-Path $parent ((Split-Path -Leaf $game) + '-SPARKYASHH-ModStorage')
    Assert-PlainPath $storage
    [void][IO.Directory]::CreateDirectory($storage)
    $lock = $null
    try {
        $lock = [IO.File]::Open((Join-Path $storage 'switch.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        $identityPath=Join-Path $storage 'profile.json'
        if (Test-Exists $identityPath) {
            $identity=Read-Json $identityPath
            if ($identity.schema -ne 1 -or $identity.gamePath -ine $game) { throw 'Хранилище принадлежит другой папке игры. Не перемещайте хранилище вручную.' }
        } else {
            if (@(Get-ChildItem -LiteralPath $storage -Force | Where-Object { $_.Name -ne 'switch.lock' }).Count -gt 0) { throw 'Найдено неизвестное хранилище без профиля. Выберите другую папку игры или проверьте хранилище вручную.' }
            Write-JsonSafe $identityPath ([ordered]@{schema=1;gamePath=$game;registeredNames=@()})
        }
        $disabled=Join-Path $storage 'DisabledFiles'; Assert-PlainPath $disabled
        [void][IO.Directory]::CreateDirectory($disabled)
    } finally { if ($null -ne $lock) { $lock.Dispose() } }
    return [pscustomobject]@{Game=$game;Storage=$storage;Disabled=$disabled;Journal=(Join-Path $storage 'operation.json')}
}
function Assert-GameClosed {
    $running=@(Get-Process -Name 'GTA5','GTA5_Enhanced','GTA5_BE','GTA5_Enhanced_BE','GTAVLauncher','PlayGTAV' -ErrorAction SilentlyContinue)
    if ($running.Count) { throw ('Закройте GTA V перед переключением: ' + (($running | Select-Object -ExpandProperty ProcessName -Unique) -join ', ')) }
}
function Move-ModExact([string]$Source,[string]$Destination) {
    Assert-PlainPath $Source; Assert-PlainPath ([IO.Path]::GetDirectoryName($Destination))
    if (Test-Exists $Destination) { throw "Файл уже существует в месте назначения: $Destination" }
    if ([IO.Path]::GetPathRoot($Source) -ine [IO.Path]::GetPathRoot($Destination)) { throw 'Хранилище должно находиться на том же диске.' }
    try {
        if ([IO.Directory]::Exists($Source)) { [IO.Directory]::Move($Source,$Destination) }
        elseif ([IO.File]::Exists($Source)) { [IO.File]::Move($Source,$Destination) }
        else { throw "Исходный файл отсутствует: $Source" }
    } catch {
        $e=$_.Exception.GetBaseException()
        throw "Не удалось переместить '$Source'. $($e.Message) [код $($e.HResult)]. Закройте OpenIV и окна Проводника с этой папкой, затем повторите. Программа не закрывает чужие процессы."
    }
}
function Get-ModState($Context,[string[]]$Names) {
    $result=@()
    foreach ($name in @($Names | Sort-Object -Unique)) {
        Assert-ModName $name
        $game=Test-Exists (Join-Path $Context.Game $name); $stored=Test-Exists (Join-Path $Context.Disabled $name)
        $state=if($game -and $stored){'Conflict'}elseif($game){'Enabled'}elseif($stored){'Disabled'}else{'Missing'}
        $result += [pscustomobject]@{Name=$name;State=$state}
    }
    return $result
}
function Get-PendingOperation($Context) {
    if (Test-Exists $Context.Journal) {
        $j=Read-Json $Context.Journal
        if ($j.schema -ne 1 -or $j.gamePath -ine $Context.Game -or @('Disable','Enable') -notcontains $j.mode) { throw 'Повреждён журнал операции. Проверьте хранилище вручную.' }
        foreach ($name in $j.names) { Assert-ModName $name }
        if (@('Moving','RollingBack','RecoveryRequired') -contains $j.state) { return $j }
    }
    return $null
}
function Restore-Operation($Context,$Journal) {
    # Inspect ALL paths first; a crash may have happened between rename and journal update.
    $sourceRoot=if($Journal.mode -eq 'Disable'){$Context.Game}else{$Context.Disabled}
    $destRoot=if($Journal.mode -eq 'Disable'){$Context.Disabled}else{$Context.Game}
    $back=New-Object System.Collections.Generic.List[string]
    foreach ($name in $Journal.names) {
        Assert-ModName $name
        $src=Join-Path $sourceRoot $name; $dst=Join-Path $destRoot $name
        Assert-PlainPath $src; Assert-PlainPath $dst
        $s=Test-Exists $src; $d=Test-Exists $dst
        if ($s -eq $d) { throw "Нельзя автоматически восстановить '$name': файл есть в обеих папках либо отсутствует в обеих. Проверьте обе папки; перезапись не выполнялась." }
        if($d){$back.Add($name)}
    }
    $Journal.state='RollingBack'; Write-JsonSafe $Context.Journal $Journal
    for($i=$back.Count-1;$i -ge 0;$i--) {
        $name=$back[$i]; Move-ModExact (Join-Path $destRoot $name) (Join-Path $sourceRoot $name)
    }
    $Journal.state='RolledBack'; Write-JsonSafe $Context.Journal $Journal
}
function Invoke-ModSwitch($Context,[ValidateSet('Disable','Enable','Recover')][string]$Mode,[string[]]$Names=@()) {
    Assert-Game $Context.Game; Assert-PlainPath $Context.Storage; Assert-PlainPath $Context.Disabled
    Assert-GameClosed
    $lock=$null
    try {
        $lock=[IO.File]::Open((Join-Path $Context.Storage 'switch.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        $pending=Get-PendingOperation $Context
        if ($Mode -eq 'Recover') {
            if($null -eq $pending){throw 'Нет прерванной операции для восстановления.'}
            Restore-Operation $Context $pending
            return 'Прежнее состояние восстановлено.'
        }
        if($null -ne $pending){throw 'Предыдущая операция не завершена. Нажмите «Восстановить».'}
        $profilePath=Join-Path $Context.Storage 'profile.json'
        $profile=Read-Json $profilePath
        if($profile.schema -ne 1 -or $profile.gamePath -ine $Context.Game){throw 'Профиль хранилища не соответствует выбранной игре.'}
        $registered=@($profile.registeredNames)
        $namesToMove=New-Object System.Collections.Generic.List[string]
        foreach($item in @(Get-ModState $Context $Names)) {
            if($Mode -eq 'Enable' -and $item.State -eq 'Disabled' -and $registered -notcontains $item.Name){throw "Неизвестный файл в хранилище: $($item.Name). Автоматическое восстановление отменено."}
            if($item.State -eq 'Conflict'){throw "Конфликт '$($item.Name)': копии есть в игре и в хранилище. Ничего не перемещено."}
            if(($Mode -eq 'Disable' -and $item.State -eq 'Enabled') -or ($Mode -eq 'Enable' -and $item.State -eq 'Disabled')) {
                Assert-PlainPath (Join-Path $Context.Game $item.Name); Assert-PlainPath (Join-Path $Context.Disabled $item.Name)
                $namesToMove.Add($item.Name)
            }
        }
        if(-not $namesToMove.Count){throw 'Нет выбранных компонентов для этой операции.'}
        if($Mode -eq 'Disable'){
            $profile.registeredNames=@(@($registered)+@($namesToMove.ToArray()) | Sort-Object -Unique)
            Write-JsonSafe $profilePath $profile
        }
        $j=[pscustomobject]@{schema=1;gamePath=$Context.Game;mode=$Mode;state='Moving';time=[DateTime]::UtcNow.ToString('o');names=@($namesToMove.ToArray())}
        Write-JsonSafe $Context.Journal $j
        $srcRoot=if($Mode -eq 'Disable'){$Context.Game}else{$Context.Disabled}
        $dstRoot=if($Mode -eq 'Disable'){$Context.Disabled}else{$Context.Game}
        try {
            foreach($name in $namesToMove){Move-ModExact (Join-Path $srcRoot $name) (Join-Path $dstRoot $name)}
            $j.state='Completed'; Write-JsonSafe $Context.Journal $j
        } catch {
            $original=$_.Exception.Message
            try { Restore-Operation $Context $j }
            catch {
                $restoreError=$_.Exception.Message; $j.state='RecoveryRequired'
                try {Write-JsonSafe $Context.Journal $j}catch{}
                throw "$original`r`nОткат не завершён: $restoreError`r`nНажмите «Восстановить» после устранения причины. Журнал: $($Context.Journal)"
            }
            throw "$original`r`nУже перемещённые компоненты возвращены обратно."
        }
        return ('Готово. Перемещено компонентов: ' + $namesToMove.Count)
    } finally {if($null -ne $lock){$lock.Dispose()}}
}
function Get-ComponentGroups($Context,[string[]]$CustomNames=@()) {
    $specs=@(
        @{Id='archives';Label='Модифицированные архивы — mods';Names=@('mods');Recommended=$true},
        @{Id='menyoo';Label='Menyoo — меню и сохранения';Names=@('Menyoo.asi','menyooStuff','Menyoo.log');Recommended=$true},
        @{Id='simpletrainer';Label='Simple Trainer — меню и настройки';Names=@('TrainerV.asi','trainerv.ini');Recommended=$true},
        @{Id='loader';Label='Загрузчик ASI и Script Hook V';Names=@('dinput8.dll','ScriptHookV.dll','ScriptHookV.log','asiloader.log');Recommended=$true},
        @{Id='dotnet';Label='ScriptHookVDotNet';Names=@('ScriptHookVDotNet.asi','ScriptHookVDotNet.dll','ScriptHookVDotNet2.dll','ScriptHookVDotNet3.dll','ScriptHookVDotNet.ini','ScriptHookVDotNet2.ini','ScriptHookVDotNet3.ini','ScriptHookVDotNet.log');Recommended=$true},
        @{Id='scripts';Label='Скрипты — scripts';Names=@('scripts');Recommended=$true},
        @{Id='graphics';Label='Графика / proxy DLL — проверьте состав';Names=@('dxgi.dll','d3d11.dll','dsound.dll','version.dll','winmm.dll','d3d9.dll','wininet.dll','winhttp.dll','dbghelp.dll','ReShade.ini','ReShade.log','ReShadePreset.ini','reshade-shaders','enbseries','enbseries.ini','enblocal.ini','d3dcompiler_46e.dll');Recommended=$false},
        @{Id='arguments';Label='Параметры запуска — весь commandline.txt';Names=@('commandline.txt');Recommended=$false}
    )
    $known=@($specs | ForEach-Object {$_.Names})
    $all=@(Get-ChildItem -LiteralPath $Context.Game -Force)+@(Get-ChildItem -LiteralPath $Context.Disabled -Force)
    $other=@($all | Where-Object {-not $_.PSIsContainer -and $_.Extension -ieq '.asi' -and $known -notcontains $_.Name} | ForEach-Object {$_.Name} | Sort-Object -Unique)
    if($other.Count){$specs+=@{Id='otherasi';Label='Остальные ASI-моды';Names=$other;Recommended=$true}}
    foreach($spec in $specs){
        $found=@(Get-ModState $Context $spec.Names | Where-Object {$_.State -ne 'Missing'})
        if($found.Count){[pscustomobject]@{Id=$spec.Id;Label=$spec.Label;Names=@($found | ForEach-Object {$_.Name});Recommended=$spec.Recommended}}
    }
    foreach($name in @($CustomNames | Sort-Object -Unique)) {
        Assert-ModName $name
        if($known -notcontains $name -and $other -notcontains $name){[pscustomobject]@{Id=('custom:'+ $name);Label=('Свой компонент — '+$name);Names=@($name);Recommended=$false}}
    }
}

# Preserve the previous Other ASI selection when Simple Trainer gets its own group.
# Apply once, so an explicit later checkbox change is never overwritten.
function Update-ComponentProfile($Profile,$Context) {
    $revision=$Profile.PSObject.Properties['groupRevision']
    if($null -ne $revision -and [int]$revision.Value -ge 2){return $false}
    $simple=@(Get-ComponentGroups $Context | Where-Object {$_.Id -eq 'simpletrainer' -and $_.Names -contains 'TrainerV.asi'})
    if($Profile.selectedIds -contains 'otherasi' -and $simple.Count){
        $Profile.selectedIds=@(@($Profile.selectedIds)+@('simpletrainer') | Sort-Object -Unique)
    }
    if($null -eq $revision){Add-Member -InputObject $Profile -NotePropertyName groupRevision -NotePropertyValue 2}
    else{$Profile.groupRevision=2}
    return $true
}
