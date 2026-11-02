# Development / Разработка

[English README](../README.md) · [Русская инструкция](../README_RU.md)

## Build

On Windows, run `tools/BUILD-LAUNCHER.cmd` once. It uses the built-in .NET Framework compiler and writes `app/GTA V Mod Switcher.exe`. Keep the `app/` directory together when running a source build.

The ready-to-run release package places the EXE at its root. The launcher starts PowerShell without a console, executes isolated preflight tests, then opens the UI. Runtime `Theme.cs` is compiled by Windows PowerShell and remains a required packaged file.

## Tests

- `app/tests/Core.Tests.ps1` — file-operation and recognized-component tests; run on Windows PowerShell 5.1 and PowerShell 7.
- `app/ModSwitch.ps1 -SmokeTest` — window initialization, profiles, component details and action state; no real GTA files are used.
- `tests/Launcher.Tests.ps1` — after building, validates GUI PE subsystem, hidden workers, failure handling and a temporary desktop shortcut.

GitHub Actions runs these tests before assembling a package. Publishing requires an explicit release marker in a push commit on main. The release job has write permission; normal test jobs use read-only permission. Published release assets are not overwritten by ordinary commits.

## Source layout

| Directory | Contents |
| --- | --- |
| `app/` | Runtime PowerShell, theme, icon, required preflight tests and diagnostic launchers |
| `src/` | Console-free EXE launcher source |
| `tools/` | Local build scripts |
| `tests/` | Built launcher tests |
| `assets/` | GitHub banner |
| `docs/` | Documentation and release notes |
| `.github/` | CI and release publishing |

The standalone `START.cmd` / `RUN-TESTS.cmd` diagnostic files show a console. Normal users should launch the ready-built EXE.

## Contributor notes

Keep group matching limited to explicitly recognized names in the game root and user-added components. Preserve same-drive, no-overwrite moves and the recovery journal. A group split must retain prior saved selections once, while respecting checkbox changes made after migration.

Code: MIT. GTA V marks belong to their respective owners. The logo artwork was generated and then exported to Windows ICO; the code license does not grant trademark rights.
