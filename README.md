# GTA V Mod Switcher by SPARKYASHH

![GTA V Mod Switcher by SPARKYASHH](assets/github-banner.png)

[![Windows tests](https://github.com/SPARKYASHH/GTAV-Mod-Switcher/actions/workflows/windows-tests.yml/badge.svg)](https://github.com/SPARKYASHH/GTAV-Mod-Switcher/actions/workflows/windows-tests.yml)

A portable Windows GUI for moving selected GTA V mod components out of the game directory and restoring them with one button.

**Version 0.1 is a preview. Windows CI passed: 26 assertions on Windows PowerShell 5.1, 26 on PowerShell 7, plus the Windows Forms smoke test. The user confirmed disable, restore and saved settings after restart on their Legacy installation. Other installations still need validation.**

[Download v0.1.1 Windows build](https://github.com/SPARKYASHH/GTAV-Mod-Switcher/releases/download/v0.1.1/GTA-V-Mod-Switcher-v0.1.1-Windows.zip) · [Windows test results](https://github.com/SPARKYASHH/GTAV-Mod-Switcher/actions/runs/41413878867)

The ready-to-run ZIP in [Releases](https://github.com/SPARKYASHH/GTAV-Mod-Switcher/releases/tag/v0.1.1) contains the EXE and does not require GitHub sign-in. [Source ZIP](https://github.com/SPARKYASHH/GTAV-Mod-Switcher/archive/refs/heads/main.zip) is also available without sign-in; compile the launcher once as described below. Version v0.1.1 is marked as a pre-release.

[Подробная инструкция на русском](README_RU.md)

## Quick start

1. Extract the ready-to-run package outside GTA and mod storage, keeping all files together.
2. Open **`GTA V Mod Switcher.exe`**. It runs the preview checks without opening CMD or PowerShell windows, then opens the application. A startup failure produces a message box and a local log path.
3. A **Code → Download ZIP source archive** does not contain the EXE: run `tools/BUILD-LAUNCHER.cmd` once to compile it with the built-in Windows .NET Framework compiler. No additional libraries are downloaded. Then open `app/GTA V Mod Switcher.exe`.
4. Select your game directory, or paste the path and press Enter. Review the selected component groups.
5. Close GTA, disable the selected mods, and use the same button to restore all components disabled by the application.

Requires Windows 10/11 and built-in Windows PowerShell 5.1. `START.cmd` and `RUN-TESTS.cmd` remain visible diagnostic launchers. Use the EXE or new desktop shortcut for normal console-free operation.

Profiles and selections are remembered per installation. Storage is automatically created beside the game directory on the same drive: `<game-directory-name>-SPARKYASHH-ModStorage/DisabledFiles`. Do not delete/move storage while it contains mods.

Groups include `mods`, Menyoo, ASI loader/Script Hook V, ScriptHookVDotNet, scripts, other ASIs, optional graphics proxies, and optional whole `commandline.txt`. Custom files/folders can be selected from the game root. Known original components, root RPF archives and EXEs are blocked. This is not a complete original-file database. Graphics candidates are unchecked by default and require review.

The tool uses same-drive moves, rejects overwrite/merge conflicts, records a recovery journal and rolls back ordinary failures. After interruption, **Восстановить** (Recover) restores the state before the interrupted operation. No other processes are killed. Close GTA, OpenIV and Explorer windows accessing mod files if access is denied. Automatic lock-owner identification is not implemented.

Before migrating from the old ModSwitch v2, restore all mods using the old switcher first. Old storage is not imported automatically.

This tool does not certify an Online-compatible installation. It does not restore original archives, change BattlEye or launcher options, or detect every possible mod. The launcher sets execution-policy bypass only for its PowerShell process; it does not change machine-wide policy or bypass organizational restrictions.

## App icon and desktop shortcut

Run `CREATE-SHORTCUT.cmd` to create a desktop shortcut with the GTA V / MODS switch icon. Keep the application in its final location before creating the shortcut. The shortcut launches the EXE without a console, including preview checks. Existing shortcuts created by this utility are updated; unrelated same-name shortcuts are not overwritten.

The icon artwork was image-generated. GTA V branding belongs to its respective owners; the code MIT license does not grant trademark rights. This is an unofficial utility.

## Startup logs

Errors are shown in a message box and recorded locally under `%LOCALAPPDATA%\SPARKYASHH\GTAVModSwitcher\logs`. Logs are never automatically uploaded.

## Development

Run `app/tests/Core.Tests.ps1` in Windows PowerShell 5.1 and PowerShell 7, then run `app/ModSwitch.ps1 -SmokeTest` on Windows. Tests cover round-trip preservation, preflight conflicts, path/original-file protection, injected move failure rollback, crash recovery, exclusive storage locking and unknown stored files.

The included GitHub Actions workflow runs Windows tests and uploads a portable test package only after success. The v0.1.1 publish job runs only for an explicitly marked release commit on main, after successful tests; ordinary commits do not publish releases. A real-installation acceptance test is still required before release.

By **SPARKYASHH**. Independent, unofficial software; not affiliated with Rockstar Games. MIT licensed. Based on the user's supplied ModSwitch v2 logic.

## Source layout

For normal use, download the **ready-to-run Windows ZIP from Releases** using the link above. You do not need the source repository.

| Directory | Contents |
| --- | --- |
| `app/` | Runtime files, app icon and required preflight tests |
| `src/` | GUI EXE launcher source |
| `tools/` | Developer build scripts |
| `tests/` | Built launcher tests |
| `assets/` | GitHub banner |
| `docs/` | Additional documentation and release notes |
| `.github/` | Automated testing and release publishing |

Build source with `tools/BUILD-LAUNCHER.cmd`, then run `app/GTA V Mod Switcher.exe`. Ready-to-run packages keep the EXE at the archive root. Keep packaged support files together with the application.
