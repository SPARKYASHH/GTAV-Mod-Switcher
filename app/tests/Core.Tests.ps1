Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '../ModSwitch.Core.ps1')
$script:Passed=0
function Assert($Condition,[string]$Message){if(-not $Condition){throw "ASSERT: $Message"}; $script:Passed++}
function Must-Fail([scriptblock]$Action){$failed=$false;try{& $Action | Out-Null}catch{$failed=$true}; Assert $failed 'Operation must fail'}
$root=Join-Path ([IO.Path]::GetTempPath()) ('Sparkyashh-tests-'+[Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($root)
try{
 $game=Join-Path $root 'GTA test — кириллица';[void][IO.Directory]::CreateDirectory($game)
 [IO.File]::WriteAllText((Join-Path $game 'GTA5.exe'),'dummy original')
 [IO.File]::WriteAllText((Join-Path $game 'Menyoo.asi'),'binary content')
 [void][IO.Directory]::CreateDirectory((Join-Path $game 'mods'))
 [IO.File]::WriteAllText((Join-Path $game 'mods/dance.ycd'),'keep these bytes')
 $ctx=Get-SwitchContext $game
 Assert (Test-Exists $ctx.Disabled) 'Storage is automatic'
 $groups=@(Get-ComponentGroups $ctx)
 Assert (@($groups | Where-Object {$_.Id -eq 'menyoo'}).Count -eq 1) 'Detect Menyoo group'
 Assert (@($groups | Where-Object {$_.Id -eq 'simpletrainer'}).Count -eq 0) 'Absent Simple Trainer is not shown'
 [IO.File]::WriteAllText((Join-Path $game 'TrainerV.asi'),'trainer binary')
 [IO.File]::WriteAllText((Join-Path $game 'trainerv.ini'),'saved settings')
 [IO.File]::WriteAllText((Join-Path $game 'OtherMod.asi'),'other plugin')
 $groups=@(Get-ComponentGroups $ctx)
 $simple=@($groups | Where-Object {$_.Id -eq 'simpletrainer'})
 Assert ($simple.Count -eq 1 -and $simple[0].Names.Count -eq 2) 'Simple Trainer includes menu and root INI'
 $other=@($groups | Where-Object {$_.Id -eq 'otherasi'})
 Assert ($other.Count -eq 1 -and $other[0].Names -contains 'OtherMod.asi' -and $other[0].Names -notcontains 'TrainerV.asi') 'Trainer is not duplicated in Other ASI'
 $saved=[pscustomobject]@{selectedIds=@('otherasi');customNames=@()}
 Assert (Update-ComponentProfile $saved $ctx) 'Existing profile upgraded once'
 Assert ($saved.selectedIds -contains 'simpletrainer') 'Previous ASI selection retained'
 $saved.selectedIds=@('otherasi')
 Assert (-not (Update-ComponentProfile $saved $ctx)) 'Profile migration is idempotent'
 Assert ($saved.selectedIds -notcontains 'simpletrainer') 'Explicit unchecked selection respected'
 Invoke-ModSwitch $ctx Disable $simple[0].Names | Out-Null
 $storedSimple=@(Get-ComponentGroups $ctx | Where-Object {$_.Id -eq 'simpletrainer'})
 Assert ($storedSimple.Count -eq 1 -and $storedSimple[0].Names.Count -eq 2) 'Stored trainer is still recognized'
 Invoke-ModSwitch $ctx Enable $storedSimple[0].Names | Out-Null
 Assert ([IO.File]::ReadAllText((Join-Path $game 'trainerv.ini')) -eq 'saved settings') 'Trainer configuration round-trip preserves data'

 Invoke-ModSwitch $ctx Disable @('mods','Menyoo.asi') | Out-Null
 Assert (-not (Test-Exists (Join-Path $game 'mods'))) 'Moved mod folder'
 Assert ((Read-Json $ctx.Journal).state -eq 'Completed') 'Completed journal'
 Invoke-ModSwitch $ctx Enable @('mods','Menyoo.asi') | Out-Null
 Assert ([IO.File]::ReadAllText((Join-Path $game 'mods/dance.ycd')) -eq 'keep these bytes') 'Round-trip preserves bytes'
 Assert ([IO.File]::ReadAllText((Join-Path $game 'GTA5.exe')) -eq 'dummy original') 'Original unchanged'
 [IO.File]::WriteAllText((Join-Path $ctx.Disabled 'Menyoo.asi'),'conflicting copy')
 Must-Fail {Invoke-ModSwitch $ctx Disable @('mods','Menyoo.asi')}
 Assert (Test-Exists (Join-Path $game 'mods')) 'Preflight prevents partial move'
 [IO.File]::Delete((Join-Path $ctx.Disabled 'Menyoo.asi'))
 foreach($bad in @('..','../outside','mods/child','GTA5.exe','update','common.rpf','steam_api64.dll')){Must-Fail {Assert-ModName $bad}}
 # Crash between rename and journal update: recover by inspecting both locations.
 $j=[pscustomobject]@{schema=1;gamePath=$ctx.Game;mode='Disable';state='Moving';names=@('mods','Menyoo.asi')}
 Write-JsonSafe $ctx.Journal $j
 Move-ModExact (Join-Path $game 'mods') (Join-Path $ctx.Disabled 'mods')
 Must-Fail {Invoke-ModSwitch $ctx Disable @('Menyoo.asi')}
 Invoke-ModSwitch $ctx Recover | Out-Null
 Assert (Test-Exists (Join-Path $game 'mods')) 'Crash recovery restores moved folder'
 Assert ((Read-Json $ctx.Journal).state -eq 'RolledBack') 'Recovery journal'
 # Fail second rename and verify first is rolled back.
 $originalMove=(Get-Command Move-ModExact).ScriptBlock
 $script:FailSource=Join-Path $game 'mods'
 function Move-ModExact([string]$Source,[string]$Destination){if($Source -eq $script:FailSource){throw 'Injected access denied'}; & $originalMove $Source $Destination}
 Must-Fail {Invoke-ModSwitch $ctx Disable @('Menyoo.asi','mods')}
 Assert (Test-Exists (Join-Path $game 'Menyoo.asi')) 'Rollback returns first move'
 Set-Item Function:Move-ModExact $originalMove
 # Exclusive storage lock blocks concurrent instances.
 $lock=[IO.File]::Open((Join-Path $ctx.Storage 'switch.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
 try{Must-Fail {Invoke-ModSwitch $ctx Disable @('mods')}}finally{$lock.Dispose()}
 Assert (Test-Exists (Join-Path $game 'mods')) 'Concurrent instance made no changes'
 # Unknown stored items are never automatically restored.
 [IO.File]::WriteAllText((Join-Path $ctx.Disabled 'unknown.ini'),'unknown')
 Must-Fail {Invoke-ModSwitch $ctx Enable @('unknown.ini')}
 Assert (-not (Test-Exists (Join-Path $game 'unknown.ini'))) 'Unknown stored item untouched'
 # Corrupt/incomplete journal must block new operations.
 [IO.File]::WriteAllText($ctx.Journal,'not json')
 Must-Fail {Invoke-ModSwitch $ctx Disable @('mods')}
 Assert (Test-Exists (Join-Path $game 'mods')) 'Corrupt journal leaves files untouched'
 Write-Host "PASS: $script:Passed assertions"
}finally{Remove-Item -LiteralPath $root -Recurse -Force}
