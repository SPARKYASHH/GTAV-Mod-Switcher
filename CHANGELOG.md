# Changelog

## v0.1.1 Preview — 2026-11-02

- First public preview with a ready-to-run ZIP, bilingual instructions and SHA-256 checksum.
- Native Windows GUI EXE starts the application without CMD or PowerShell windows.
- Preflight checks still run; startup failures show a message with a local log path.
- Desktop shortcuts now target the EXE; existing utility shortcuts can be updated.
- Added built-in compiler build script and CI checks for GUI subsystem, hidden workers and startup failure handling.

## 0.1.0-preview — 2026-11-01

- Windows Forms interface, saved installation profiles, path paste/browse.
- Automatic same-drive storage, component groups and custom root components.
- One button to disable a selected set and restore all previously disabled items.
- Exclusive storage lock, original-file/path safeguards, no overwrite or merge.
- Durable operation plan, ordinary failure rollback and interrupted-operation recovery.
- Russian/English documentation and Windows CI tests.
- Windows Server 2022 CI passed: PowerShell 5.1 (26 assertions), PowerShell 7 (26 assertions), WinForms smoke test.
- User confirmed disable, restore, restart and saved settings on their installation.
- Added the approved GTA V switch icon, optional desktop shortcut and GitHub banner.
- Added a restrained light/forest-green interface, readable component rows and separate group details.
- Further real-installation coverage, including Enhanced, remains pending.
