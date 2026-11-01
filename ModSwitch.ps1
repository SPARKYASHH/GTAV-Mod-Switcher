# GTA V Mod Switcher by SPARKYASHH -- graphical launcher, Windows PowerShell 5.1
#Requires -Version 5.1
[CmdletBinding()]
param([switch]$SmokeTest,[string]$PreviewPath)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
Add-Type -Path (Join-Path $PSScriptRoot 'Theme.cs') -ReferencedAssemblies 'System.Windows.Forms','System.Drawing'
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
$form.ClientSize=New-Object Drawing.Size(1000,770)
$form.MinimumSize=New-Object Drawing.Size(1016,809)
$form.MaximumSize=New-Object Drawing.Size(1016,809)
$form.MaximizeBox=$false
$form.StartPosition='CenterScreen'
$form.AutoScaleMode='Dpi'
$form.AutoScaleDimensions=New-Object Drawing.SizeF(96,96)
$form.Font=New-Object Drawing.Font('Segoe UI',10)
$form.BackColor=[Drawing.Color]::FromArgb(247,248,245)
$form.ForeColor=[Drawing.Color]::FromArgb(32,39,35)
$appIcon=$null
$iconPath=Join-Path $PSScriptRoot 'assets/app.ico'
if(Test-Exists $iconPath){$appIcon=New-Object Drawing.Icon($iconPath);$form.Icon=$appIcon}
function New-Label([string]$Text,[int]$X,[int]$Y,[int]$Width,[int]$Height){
 $c=New-Object Windows.Forms.Label;$c.Text=$Text;$c.Location=New-Object Drawing.Point($X,$Y);$c.Size=New-Object Drawing.Size($Width,$Height);$form.Controls.Add($c);return $c
}
function New-Button([string]$Text,[int]$X,[int]$Y,[int]$Width,[int]$Height){
 $c=New-Object Windows.Forms.Button;$c.Text=$Text;$c.Location=New-Object Drawing.Point($X,$Y);$c.Size=New-Object Drawing.Size($Width,$Height);$c.FlatStyle='Flat';$c.FlatAppearance.BorderColor=[Drawing.Color]::FromArgb(210,217,209);$c.FlatAppearance.MouseOverBackColor=[Drawing.Color]::FromArgb(234,241,234);$c.BackColor=[Drawing.Color]::White;$c.Cursor=[Windows.Forms.Cursors]::Hand;$form.Controls.Add($c);return $c
}
$brandPicture=New-Object Windows.Forms.PictureBox
$brandPicture.Location=New-Object Drawing.Point(32,27);$brandPicture.Size=New-Object Drawing.Size(48,48);$brandPicture.SizeMode='Zoom'
$brandBitmap=$null
if($null -ne $appIcon){$brandBitmap=$appIcon.ToBitmap();$brandPicture.Image=$brandBitmap}
$form.Controls.Add($brandPicture)
$title=New-Label 'GTA V Mod Switcher' 96 22 820 38
$title.Font=New-Object Drawing.Font('Segoe UI',20,[Drawing.FontStyle]::Bold)
$credit=New-Label 'by SPARKYASHH' 98 63 780 24
$credit.ForeColor=[Drawing.Color]::FromArgb(103,113,107)
$separator=New-Label '' 32 104 936 1
$separator.BackColor=[Drawing.Color]::FromArgb(220,225,218)
$pathLabel=New-Label 'Папка игры' 32 122 780 24
$pathBox=New-Object Windows.Forms.ComboBox
$pathBox.Location=New-Object Drawing.Point(32,152);$pathBox.Size=New-Object Drawing.Size(752,30);$pathBox.DropDownStyle='DropDown';$pathBox.FlatStyle='Flat';$pathBox.BackColor=[Drawing.Color]::White;$form.Controls.Add($pathBox)
foreach($p in $script:Settings.profiles){[void]$pathBox.Items.Add($p.gamePath)}
$browse=New-Button 'Обзор…' 800 149 168 34
$status=New-Label '●  Выберите папку GTA V' 32 202 936 28
$status.ForeColor=[Drawing.Color]::FromArgb(37,92,60)
$status.Font=New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
$statusHint=New-Label 'Можно вставить путь в поле и нажать Enter. Поддерживаются отдельные профили установок.' 32 234 936 24
$statusHint.ForeColor=[Drawing.Color]::FromArgb(103,113,107)
$statusHint.Font=New-Object Drawing.Font('Segoe UI',9)
$leftCard=New-Object Sparkyashh.Card
$leftCard.Location=New-Object Drawing.Point(32,278);$leftCard.Size=New-Object Drawing.Size(440,276);$form.Controls.Add($leftCard)
$list=New-Object Sparkyashh.GroupList
$list.Location=New-Object Drawing.Point(12,10);$list.Size=New-Object Drawing.Size(416,254);$leftCard.Controls.Add($list)
$rightCard=New-Object Sparkyashh.Card
$rightCard.Location=New-Object Drawing.Point(488,278);$rightCard.Size=New-Object Drawing.Size(480,276);$form.Controls.Add($rightCard)
$detailsTitle=New-Object Windows.Forms.Label
$detailsTitle.Text='Состав группы';$detailsTitle.Location=New-Object Drawing.Point(22,20);$detailsTitle.Size=New-Object Drawing.Size(436,30);$detailsTitle.Font=New-Object Drawing.Font('Segoe UI',13,[Drawing.FontStyle]::Bold);$rightCard.Controls.Add($detailsTitle)
$details=New-Object Windows.Forms.TextBox
$details.Location=New-Object Drawing.Point(22,64);$details.Size=New-Object Drawing.Size(436,190);$details.Multiline=$true;$details.ReadOnly=$true;$details.ScrollBars='Vertical';$details.BorderStyle='None';$details.BackColor=[Drawing.Color]::White;$details.ForeColor=[Drawing.Color]::FromArgb(66,76,69);$rightCard.Controls.Add($details)
$addFile=New-Button 'Добавить файл…' 32 568 138 34
$addFolder=New-Button 'Добавить папку…' 180 568 146 34
$refresh=New-Button 'Обновить' 336 568 136 34
$recover=New-Button 'Восстановить' 800 568 168 34
$storageCaption=New-Label 'Путь к хранилищу модов' 32 622 680 23
$storageCaption.ForeColor=[Drawing.Color]::FromArgb(103,113,107)
$storageLabel=New-Label 'Будет создано автоматически рядом с папкой игры.' 32 651 728 27
$storageLabel.AutoEllipsis=$true
$openStorage=New-Button 'Открыть хранилище' 776 639 192 36
$toggle=New-Button 'Выберите папку игры' 628 699 340 46
$toggle.BackColor=[Drawing.Color]::FromArgb(37,92,60);$toggle.ForeColor=[Drawing.Color]::White;$toggle.FlatAppearance.BorderSize=0;$toggle.FlatAppearance.MouseOverBackColor=[Drawing.Color]::FromArgb(29,75,48);$toggle.Font=New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
$note=New-Label 'Переключаются выбранные компоненты. Параметры BattlEye не меняются; полная чистота игры для Online не проверяется.' 32 702 565 43
$note.Font=New-Object Drawing.Font('Segoe UI',9)
$note.ForeColor=[Drawing.Color]::FromArgb(103,113,107)
$tip=New-Object Windows.Forms.ToolTip
$tip.SetToolTip($pathBox,'Выберите папку GTA V или вставьте полный путь и нажмите Enter.')
$tip.SetToolTip($recover,'Вернуть состояние до прерванного переключения.')
function Get-GroupCaption($Group){
 switch($Group.Id){
  'archives'{return 'Папка mods'}
  'menyoo'{return 'Menyoo'}
  'loader'{return 'Script Hook V'}
  'dotnet'{return 'ScriptHookVDotNet'}
  'scripts'{return 'Скрипты'}
  'graphics'{return 'Графические моды'}
  'arguments'{return 'Параметры запуска'}
  'otherasi'{return 'Другие ASI-моды'}
  default{return $Group.Label}
 }
}
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
 if($list.SelectedIndices.Count -eq 0){$detailsTitle.Text='Состав группы';$details.Text='Выберите группу слева, чтобы увидеть её файлы и их расположение.';return}
 $g=$script:Groups[$list.SelectedIndices[0]]
 $detailsTitle.Text=Get-GroupCaption $g
 $lines=@('Файлы и папки:','')
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
 if(-not $ready){
  $script:Loading=$true;try{$list.Items.Clear()}finally{$script:Loading=$false}
  $status.Text='●  Выберите папку GTA V';$statusHint.Text='Вставьте полный путь и нажмите Enter или воспользуйтесь кнопкой «Обзор…».'
  $storageLabel.Text='Будет создано автоматически рядом с папкой игры.'
  $toggle.Text='Выберите папку игры';Update-Details;return
 }
 $profile=Get-CurrentProfile
 $script:Loading=$true
 try{
  $script:Groups=@(Get-ComponentGroups $script:Context $profile.customNames)
  $list.Items.Clear()
  foreach($g in $script:Groups){
   $row=New-Object Windows.Forms.ListViewItem((Get-GroupCaption $g))
   $row.Checked=$profile.selectedIds -contains $g.Id
   [void]$list.Items.Add($row)
  }
 }finally{$script:Loading=$false}
 $stored=@(Get-ChildItem -LiteralPath $script:Context.Disabled -Force)
 $allNames=@($script:Groups | ForEach-Object {$_.Names})
 $states=@(Get-ModState $script:Context $allNames)
 $conflicts=@($states | Where-Object {$_.State -eq 'Conflict'})
 $pending=Get-PendingOperation $script:Context
 $storageLabel.Text=$script:Context.Storage
 $tip.SetToolTip($storageLabel,$script:Context.Storage)
 $status.ForeColor=[Drawing.Color]::FromArgb(37,92,60)
 if($null -ne $pending){
  $status.Text='●  Переключение прервано'
  $statusHint.Text='Нажмите «Восстановить», чтобы вернуть прежнее состояние.'
  $status.ForeColor=[Drawing.Color]::FromArgb(151,93,27)
  $toggle.Enabled=$false;$recover.Enabled=$true
 }elseif($conflicts.Count){
  $status.Text='●  Обнаружены конфликты файлов'
  $statusHint.Text='Посмотрите состав групп и проверьте копии в игре и в хранилище.'
  $status.ForeColor=[Drawing.Color]::FromArgb(164,54,47)
  $toggle.Enabled=$false
 }elseif($stored.Count){
  $status.Text='●  Есть отключённые моды'
  $statusHint.Text='Компонентов в хранилище: '+$stored.Count+'. Кнопка вернёт их все, независимо от галочек.'
  $toggle.Text='Включить отключённые моды'
 }else{
  $status.Text='●  Моды включены'
  $statusHint.Text='В хранилище нет компонентов. Галочками выберите, что отключить.'
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
  # ListView selection collections need native handles, including in a hidden test window.
  [void]$form.Handle;[void]$list.Handle
  $fakeGame=Join-Path $smokeRoot 'GTA V Test'
  [void][IO.Directory]::CreateDirectory($fakeGame)
  [IO.File]::WriteAllText((Join-Path $fakeGame 'GTA5.exe'),'TEST ONLY')
  [IO.File]::WriteAllText((Join-Path $fakeGame 'Menyoo.asi'),'TEST ONLY')
  Select-Game $fakeGame
  if($null -eq $appIcon){throw 'GUI: application icon missing'}
  if($list.Items.Count -ne 1 -or $list.CheckedItems.Count -ne 1){throw 'GUI: default Menyoo selection failed'}
  $list.Items[0].Selected=$true;Update-Details
  if($details.Text -notmatch 'Menyoo.asi'){throw 'GUI: component details missing'}
  if($toggle.Text -ne 'Отключить выбранные моды'){throw 'GUI: wrong initial action'}
  Invoke-ModSwitch $script:Context Disable @('Menyoo.asi') | Out-Null
  Update-View
  if($toggle.Text -ne 'Включить отключённые моды'){throw 'GUI: wrong restore action'}
  Invoke-ModSwitch $script:Context Enable @('Menyoo.asi') | Out-Null
  if($PreviewPath){
   foreach($name in @('mods','scripts','menyooStuff')){[void][IO.Directory]::CreateDirectory((Join-Path $fakeGame $name))}
   foreach($name in @('ScriptHookV.dll','dinput8.dll','dxgi.dll')){[IO.File]::WriteAllText((Join-Path $fakeGame $name),'TEST ONLY')}
   Update-View
   $form.Show();[Windows.Forms.Application]::DoEvents()
   $list.Items[1].Selected=$true;Update-Details
   $bitmap=New-Object Drawing.Bitmap($form.Width,$form.Height)
   try{$form.DrawToBitmap($bitmap,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$bitmap.Save($PreviewPath,[Drawing.Imaging.ImageFormat]::Png)}finally{$bitmap.Dispose()}
  }
  Write-Host 'PASS: GUI initialization, saved profile, group defaults, details, automatic toggle state'
 }finally{$form.Dispose();$tip.Dispose();if($null -ne $brandBitmap){$brandBitmap.Dispose()};if($null -ne $appIcon){$appIcon.Dispose()};if(Test-Exists $smokeRoot){Remove-Item -LiteralPath $smokeRoot -Recurse -Force}}
}else{
 [void]$form.ShowDialog()
 $form.Dispose()
 $tip.Dispose()
 if($null -ne $brandBitmap){$brandBitmap.Dispose()}
 if($null -ne $appIcon){$appIcon.Dispose()}
}
