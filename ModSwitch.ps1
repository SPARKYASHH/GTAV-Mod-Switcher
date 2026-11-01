# GTA V Mod Switcher by SPARKYASHH -- graphical launcher, Windows PowerShell 5.1
#Requires -Version 5.1
[CmdletBinding()]
param([switch]$SmokeTest)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
. (Join-Path $PSScriptRoot 'ModSwitch.Core.ps1')
$script:Context=$null
$script:Groups=@()
$script:Busy=$false
$script:Loading=$false
$script:SettingsDir=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'SPARKYASHH/GTAVModSwitcher'
$smokeRoot=$null
if($SmokeTest){
 $smokeRoot=Join-Path ([IO.Path]::GetTempPath()) ('Sparkyashh-GUI-test-'+[Guid]::NewGuid().ToString('N'))
 $script:SettingsDir=Join-Path $smokeRoot 'settings'
}
[void][IO.Directory]::CreateDirectory($script:SettingsDir)
$script:SettingsFile=Join-Path $script:SettingsDir 'settings.json'
$script:Settings=[pscustomobject]@{schema=1;lastGame='';profiles=@()}
try{if(Test-Exists $script:SettingsFile){$script:Settings=Read-Json $script:SettingsFile;if($script:Settings.schema -ne 1){throw 'Неизвестная версия настроек.'}}}catch{[Windows.Forms.MessageBox]::Show("Не удалось прочитать настройки. Исходный файл сохранён; программа завершится.`r`n$($_.Exception.Message)",'Ошибка настроек')|Out-Null;exit 1}

$form=New-Object Windows.Forms.Form
$form.Text='GTA V Mod Switcher by SPARKYASHH'
$form.ClientSize=New-Object Drawing.Size(920,700)
$form.MinimumSize=New-Object Drawing.Size(936,739)
$form.StartPosition='CenterScreen'
$form.Font=New-Object Drawing.Font('Segoe UI',10)
$form.BackColor=[Drawing.Color]::FromArgb(244,246,250)
function New-Label([string]$Text,[int]$X,[int]$Y,[int]$Width,[int]$Height){
 $c=New-Object Windows.Forms.Label;$c.Text=$Text;$c.Location=New-Object Drawing.Point($X,$Y);$c.Size=New-Object Drawing.Size($Width,$Height);$form.Controls.Add($c);return $c
}
function New-Button([string]$Text,[int]$X,[int]$Y,[int]$Width,[int]$Height){
 $c=New-Object Windows.Forms.Button;$c.Text=$Text;$c.Location=New-Object Drawing.Point($X,$Y);$c.Size=New-Object Drawing.Size($Width,$Height);$c.FlatStyle='Flat';$c.BackColor=[Drawing.Color]::White;$form.Controls.Add($c);return $c
}
$title=New-Label 'GTA V Mod Switcher' 24 18 650 36
$title.Font=New-Object Drawing.Font('Segoe UI',19,[Drawing.FontStyle]::Bold)
$credit=New-Label 'by SPARKYASHH  |  Предварительная версия 0.1' 26 58 700 26
$credit.ForeColor=[Drawing.Color]::FromArgb(85,96,115)
$pathLabel=New-Label 'Папка GTA V — выберите папку или вставьте путь и нажмите Enter:' 24 96 850 25
$pathBox=New-Object Windows.Forms.ComboBox
$pathBox.Location=New-Object Drawing.Point(24,124);$pathBox.Size=New-Object Drawing.Size(704,30);$pathBox.DropDownStyle='DropDown';$form.Controls.Add($pathBox)
foreach($p in $script:Settings.profiles){[void]$pathBox.Items.Add($p.gamePath)}
$browse=New-Button 'Выбрать папку…' 744 122 152 32
$storageLabel=New-Label 'Хранилище создастся автоматически рядом с папкой игры.' 24 163 870 38
$status=New-Label 'Сначала выберите папку GTA V.' 24 206 870 32
$status.Font=New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
$groupsLabel=New-Label 'Выберите группы для отключения. Справа — точный состав выбранной группы.' 24 247 870 25
$list=New-Object Windows.Forms.CheckedListBox
$list.Location=New-Object Drawing.Point(24,278);$list.Size=New-Object Drawing.Size(450,224);$list.CheckOnClick=$true;$list.IntegralHeight=$false;$form.Controls.Add($list)
$details=New-Object Windows.Forms.TextBox
$details.Location=New-Object Drawing.Point(490,278);$details.Size=New-Object Drawing.Size(406,224);$details.Multiline=$true;$details.ReadOnly=$true;$details.ScrollBars='Vertical';$details.BackColor=[Drawing.Color]::White;$form.Controls.Add($details)
$addFile=New-Button 'Добавить файл…' 24 514 145 34
$addFolder=New-Button 'Добавить папку…' 177 514 151 34
$refresh=New-Button 'Обновить список' 336 514 138 34
$openStorage=New-Button 'Открыть хранилище' 490 514 194 34
$recover=New-Button 'Восстановить' 700 514 196 34
$toggle=New-Button 'Выберите папку игры' 24 563 872 48
$toggle.BackColor=[Drawing.Color]::FromArgb(41,93,210);$toggle.ForeColor=[Drawing.Color]::White;$toggle.Font=New-Object Drawing.Font('Segoe UI',12,[Drawing.FontStyle]::Bold)
$note=New-Label 'Переключатель работает с выбранными файлами. Оригинальные архивы и параметры BattlEye не изменяются. Отключение выбранных модов не подтверждает полную чистоту игры для Online.' 24 624 872 62
$note.Font=New-Object Drawing.Font('Segoe UI',9)
$note.ForeColor=[Drawing.Color]::FromArgb(85,96,115)
function Show-Error([string]$Message){[void][Windows.Forms.MessageBox]::Show($form,$Message,'GTA V Mod Switcher','OK','Error')}
function Get-CurrentProfile {
 return @($script:Settings.profiles | Where-Object {$_.gamePath -ieq $script:Context.Game})[0]
}
function Save-Settings {
 Write-JsonSafe $script:SettingsFile $script:Settings
}
function Assert-DisplayedGame {
 if($null -eq $script:Context -or (Get-FullPath ($pathBox.Text.Trim().Trim('"'))) -ine $script:Context.Game){throw 'Путь изменён. Сначала нажмите Enter, чтобы открыть эту папку игры.'}
}
function Save-Selection {
 if($script:Loading -or $null -eq $script:Context){return}
 $p=Get-CurrentProfile
 $p.selectedIds=@($list.CheckedIndices | ForEach-Object {$script:Groups[$_].Id})
 Save-Settings
}
function Update-Details {
 if($list.SelectedIndex -lt 0){$details.Text='Выберите строку, чтобы увидеть все входящие в группу файлы и папки.';return}
 $g=$script:Groups[$list.SelectedIndex]
 $lines=@($g.Label,'')
 foreach($item in @(Get-ModState $script:Context $g.Names)){
  $label=switch($item.State){'Enabled'{'в игре'}
   'Disabled'{'в хранилище'}
   'Conflict'{'КОНФЛИКТ — две копии'}
   default{'не найден'}}
  $lines+=($item.Name+' — '+$label)
 }
 $details.Text=$lines -join "`r`n"
}
function Update-View {
 $ready=$null -ne $script:Context
 foreach($c in @($list,$addFile,$addFolder,$refresh,$openStorage,$toggle)){$c.Enabled=$ready -and -not $script:Busy}
 $recover.Enabled=$false
 if(-not $ready){return}
 $profile=Get-CurrentProfile
 $script:Loading=$true
 try{
  $script:Groups=@(Get-ComponentGroups $script:Context $profile.customNames)
  $list.Items.Clear()
  foreach($g in $script:Groups){[void]$list.Items.Add($g.Label,($profile.selectedIds -contains $g.Id))}
 }finally{$script:Loading=$false}
 $stored=@(Get-ChildItem -LiteralPath $script:Context.Disabled -Force)
 $allNames=@($script:Groups | ForEach-Object {$_.Names})
 $states=@(Get-ModState $script:Context $allNames)
 $conflicts=@($states | Where-Object {$_.State -eq 'Conflict'})
 $pending=Get-PendingOperation $script:Context
 $storageLabel.Text='Хранилище: '+$script:Context.Storage
 if($null -ne $pending){
  $status.Text='Предыдущая операция прервана. Сначала восстановите прежнее состояние.'
  $toggle.Enabled=$false;$recover.Enabled=$true
 }elseif($conflicts.Count){
  $status.Text='Обнаружены конфликты. Посмотрите состав групп и проверьте обе папки.'
  $toggle.Enabled=$false
 }elseif($stored.Count){
  $status.Text='Временно отключено компонентов: '+$stored.Count
  $toggle.Text='Включить отключённые моды'
 }else{
  $status.Text='Компонентов в хранилище нет. Выберите группы для отключения.'
  $toggle.Text='Отключить выбранные моды'
 }
 Update-Details
}
function Select-Game([string]$Path){
 $newContext=Get-SwitchContext $Path
 $script:Context=$newContext
 $profile=@($script:Settings.profiles | Where-Object {$_.gamePath -ieq $newContext.Game})
 if(-not $profile.Count){
  $groups=@(Get-ComponentGroups $newContext)
  $p=[pscustomobject]@{gamePath=$newContext.Game;selectedIds=@($groups | Where-Object {$_.Recommended} | ForEach-Object {$_.Id});customNames=@()}
  $script:Settings.profiles=@($script:Settings.profiles)+@($p)
 }
 $script:Settings.lastGame=$newContext.Game
 if(-not $pathBox.Items.Contains($newContext.Game)){[void]$pathBox.Items.Add($newContext.Game)}
 Save-Settings
 Update-View
}
function Add-Custom([string]$Path){
 if((Get-FullPath ([IO.Path]::GetDirectoryName($Path))) -ine $script:Context.Game){throw 'Выберите файл или папку непосредственно в корне GTA V. Для вложенных файлов выберите их корневую папку целиком.'}
 $name=Split-Path -Leaf $Path;Assert-ModName $name;Assert-PlainPath $Path
 $already=@($script:Groups | Where-Object {$_.Names -contains $name})
 $p=Get-CurrentProfile
 if($already.Count){$id=$already[0].Id}else{
  $p.customNames=@(@($p.customNames)+@($name)|Sort-Object -Unique);$id='custom:'+$name
 }
 $p.selectedIds=@(@($p.selectedIds)+@($id)|Sort-Object -Unique)
 Save-Settings;Update-View
}
$browse.Add_Click({
 $d=New-Object Windows.Forms.FolderBrowserDialog;$d.Description='Выберите папку, где расположен GTA5.exe или GTA5_Enhanced.exe';$d.ShowNewFolderButton=$false
 if($null -ne $script:Context){$d.SelectedPath=$script:Context.Game}
 try{if($d.ShowDialog($form) -eq 'OK'){
  Select-Game $d.SelectedPath
  $script:Loading=$true;try{$pathBox.SelectedItem=$script:Context.Game}finally{$script:Loading=$false}
 }}catch{Show-Error $_.Exception.Message}finally{$d.Dispose()}
})
$pathBox.Add_KeyDown({param($sender,$e) if($e.KeyCode -eq 'Enter'){
 $e.SuppressKeyPress=$true
 try{Select-Game ($pathBox.Text.Trim().Trim('"'))}catch{$script:Context=$null;Update-View;Show-Error $_.Exception.Message}
}})
$pathBox.Add_SelectedIndexChanged({if(-not $script:Loading){try{Select-Game ([string]$pathBox.SelectedItem)}catch{$script:Context=$null;Update-View;Show-Error $_.Exception.Message}}})
$list.Add_SelectedIndexChanged({try{Update-Details}catch{Show-Error $_.Exception.Message}})
# ItemCheck fires before the checked collection changes; persist once the event completes.
$list.Add_ItemCheck({if(-not $script:Loading){[void]$form.BeginInvoke([Action]{try{Save-Selection}catch{Show-Error $_.Exception.Message}})}})
$refresh.Add_Click({try{Save-Selection;Update-View}catch{Show-Error $_.Exception.Message}})
$openStorage.Add_Click({try{Start-Process explorer.exe -ArgumentList ('"'+$script:Context.Storage+'"')}catch{Show-Error $_.Exception.Message}})
$addFile.Add_Click({
 $d=New-Object Windows.Forms.OpenFileDialog;$d.InitialDirectory=$script:Context.Game;$d.Multiselect=$true
 try{if($d.ShowDialog($form) -eq 'OK'){foreach($file in $d.FileNames){Add-Custom $file}}}catch{Show-Error $_.Exception.Message}finally{$d.Dispose()}
})
$addFolder.Add_Click({
 $d=New-Object Windows.Forms.FolderBrowserDialog;$d.SelectedPath=$script:Context.Game;$d.ShowNewFolderButton=$false
 try{if($d.ShowDialog($form) -eq 'OK'){Add-Custom $d.SelectedPath}}catch{Show-Error $_.Exception.Message}finally{$d.Dispose()}
})
function Run-Operation([string]$Mode,[string[]]$Names=@()){
 $script:Busy=$true;$form.UseWaitCursor=$true
 foreach($c in @($toggle,$recover,$browse,$pathBox,$list,$addFile,$addFolder,$refresh,$openStorage)){$c.Enabled=$false}
 try{
  $message=Invoke-ModSwitch $script:Context $Mode $Names
  [void][Windows.Forms.MessageBox]::Show($form,$message,'GTA V Mod Switcher','OK','Information')
 }catch{Show-Error $_.Exception.Message}
 finally{
  $script:Busy=$false;$form.UseWaitCursor=$false;$browse.Enabled=$true;$pathBox.Enabled=$true
  try{Update-View}catch{$toggle.Enabled=$false;$recover.Enabled=$false;Show-Error $_.Exception.Message}
 }
}
$toggle.Add_Click({
 try{
  Assert-DisplayedGame
  Save-Selection
  $stored=@(Get-ChildItem -LiteralPath $script:Context.Disabled -Force)
  if($stored.Count){Run-Operation 'Enable' @($stored | ForEach-Object {$_.Name})}
  else{
   $names=@($list.CheckedIndices | ForEach-Object {$script:Groups[$_].Names} | Sort-Object -Unique)
   if(-not $names.Count){throw 'Отметьте хотя бы одну группу.'}
   Run-Operation 'Disable' $names
  }
 }catch{Show-Error $_.Exception.Message}
})
$recover.Add_Click({try{Assert-DisplayedGame;Run-Operation 'Recover'}catch{Show-Error $_.Exception.Message}})
$form.Add_FormClosing({param($sender,$eventArgs) if($script:Busy){$eventArgs.Cancel=$true}else{try{Save-Selection}catch{Show-Error $_.Exception.Message;$eventArgs.Cancel=$true}}})
$form.Add_Shown({
 try{
  if($script:Settings.lastGame -and $pathBox.Items.Contains($script:Settings.lastGame)){$pathBox.SelectedItem=$script:Settings.lastGame}
  else{Update-View}
 }catch{Show-Error $_.Exception.Message}
})
if($SmokeTest){
 try{
  $fakeGame=Join-Path $smokeRoot 'GTA V Test'
  [void][IO.Directory]::CreateDirectory($fakeGame)
  [IO.File]::WriteAllText((Join-Path $fakeGame 'GTA5.exe'),'TEST ONLY')
  [IO.File]::WriteAllText((Join-Path $fakeGame 'Menyoo.asi'),'TEST ONLY')
  Select-Game $fakeGame
  if($list.Items.Count -ne 1 -or $list.CheckedItems.Count -ne 1){throw 'GUI: default Menyoo selection failed'}
  $list.SelectedIndex=0;Update-Details
  if($details.Text -notmatch 'Menyoo.asi'){throw 'GUI: component details missing'}
  if($toggle.Text -ne 'Отключить выбранные моды'){throw 'GUI: wrong initial action'}
  Invoke-ModSwitch $script:Context Disable @('Menyoo.asi') | Out-Null
  Update-View
  if($toggle.Text -ne 'Включить отключённые моды'){throw 'GUI: wrong restore action'}
  Invoke-ModSwitch $script:Context Enable @('Menyoo.asi') | Out-Null
  Write-Host 'PASS: GUI initialization, saved profile, group defaults, details, automatic toggle state'
 }finally{$form.Dispose();if(Test-Exists $smokeRoot){Remove-Item -LiteralPath $smokeRoot -Recurse -Force}}
}else{
 [void]$form.ShowDialog()
 $form.Dispose()
}
