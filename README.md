**English** | [Русский](README_RU.md)

# GTA V Mod Switcher by SPARKYASHH

![GTA V Mod Switcher](assets/github-banner.png)

[![Windows tests](https://github.com/SPARKYASHH/GTAV-Mod-Switcher/actions/workflows/windows-tests.yml/badge.svg)](https://github.com/SPARKYASHH/GTAV-Mod-Switcher/actions/workflows/windows-tests.yml)

**Move your GTA V mods out of the game folder before playing GTA Online, then restore them for modded Story Mode — with one button.**

A portable Windows mod manager for enabling and disabling selected GTA V mods. Choose your game directory once; the app remembers your selection and creates storage automatically beside the game folder.

**[Download Windows ZIP with EXE](https://github.com/SPARKYASHH/GTAV-Mod-Switcher/releases/download/v0.1.2/GTA-V-Mod-Switcher-v0.1.2-Windows.zip)** · [All releases](https://github.com/SPARKYASHH/GTAV-Mod-Switcher/releases)

## Quick start

1. Extract the complete Windows ZIP to a permanent folder **outside GTA and mod storage**.
2. Open **`GTA V Mod Switcher.exe`**. Only the app window opens; no console appears.
3. Select your GTA directory, or paste its path and press Enter.
4. Review the checked groups. Select a group to see its exact files on the right.
5. Close GTA, then click **Отключить выбранные моды** (Disable selected mods). The selected files move into storage.
6. Click **Включить отключённые моды** (Restore disabled mods) to return everything previously moved by the app, regardless of the current checkboxes.

Optional: run `CREATE-SHORTCUT.cmd` once to create or update the desktop shortcut. The current app interface is in Russian; these instructions explain the controls in English.

## Which mods are detected?

Groups appear when matching files are found in your GTA directory or the app's storage. These are your **already installed files**; the list is not a bundled mod collection.

| Group | Common files or folders |
| --- | --- |
| Menyoo | `Menyoo.asi`, `menyooStuff` |
| Simple Trainer | `TrainerV.asi`, `trainerv.ini` in the game root |
| ASI loader / Script Hook V | `dinput8.dll`, `ScriptHookV.dll` |
| ScriptHookVDotNet | ASI, .NET libraries and settings |
| Modded archives and scripts | `mods`, `scripts` |
| Other ASI mods | Other `.asi` plugins in the game root |
| Graphics mods — review first | Known ReShade / ENB names and proxy DLLs |
| Launch arguments — optional | The complete `commandline.txt` |

Use **Добавить файл…** / **Добавить папку…** to select additional files or folders from the GTA root. Graphics candidates are unchecked by default: review their contents before selecting them. Simple Trainer settings kept in AppData stay there; only matching files inside GTA are moved. See the [Simple Trainer author's instructions](https://www.gta5-mods.com/scripts/simple-trainer-for-gtav).

## Storage and GTA Online

Storage is created on the same drive, beside GTA: `<game-folder-name>-SPARKYASHH-ModStorage/DisabledFiles`. Moves keep your mods available for restoration; existing destination files are never overwritten. **Keep storage while it contains disabled mods.** Paths, selections and installation profiles are saved automatically.

**Before GTA Online:** the app moves the components you selected. Check that your selection covers your installed mods and that the original game files are intact. BattlEye and Steam/Rockstar launch options remain under your control. Moving selected files does not certify an Online-compatible installation.

## Requirements and troubleshooting

- **Windows 10/11**, with built-in Windows PowerShell 5.1 and .NET Framework. No Python or additional libraries need installing.
- Disable/restore, saved settings and console-free launch were verified on the author's **GTA V Legacy** installation. Enhanced paths are recognized; a real Enhanced installation has not been validated.
- **App does not open:** extract every file and use the ready-to-run ZIP from Releases. A startup error shows a local log path: `%LOCALAPPDATA%\SPARKYASHH\GTAVModSwitcher\logs`.
- **Access denied:** close GTA, OpenIV and Explorer windows accessing the mod folders, then retry.
- **Two copies / interrupted move:** review both folders; use **Восстановить** (Recover) for an interrupted operation. The app refuses to overwrite conflicting copies.

[More troubleshooting](docs/TROUBLESHOOTING.md#english) · [Build from source](docs/DEVELOPMENT.md)

By **SPARKYASHH** · [MIT license](LICENSE) · Independent, unofficial utility; not affiliated with Rockstar Games.
