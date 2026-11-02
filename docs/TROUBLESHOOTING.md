# Troubleshooting / Решение проблем

[English README](../README.md) · [Русская инструкция](../README_RU.md)

<a id="english"></a>
## English

**Startup failure.** Extract the whole ready-to-run ZIP before launching the EXE. Keep support files together. A message box identifies the local startup log under `%LOCALAPPDATA%\SPARKYASHH\GTAVModSwitcher\logs`. Logs are not automatically uploaded. The EXE runs temporary-file preflight tests before opening the main window; a failed check blocks startup.

**Access denied.** Close GTA V, OpenIV and Explorer windows accessing the affected folders. Check that your Windows account has write access to the game folder and its parent, where storage is created. The utility does not terminate other processes or close their file handles. It does not automatically request administrator rights.

**Conflicting copies.** Compare the game folder and storage. Move an unwanted duplicate to a separate backup directory after identifying which copy to keep. The app refuses to merge or overwrite either copy.

**Interrupted operation.** Use **Восстановить** (Recover) to return to the state before the interrupted switch. This may enable or disable components depending on the interrupted operation. If recovery reports both copies or a missing file, resolve that conflict first. Keep `operation.json`; deleting the journal does not resolve the underlying file state.

**Missing group.** Groups describe files found in the game directory or storage. Use Refresh after installing a mod, and review newly appearing groups. Add custom root files/folders explicitly. For files nested under a root folder, select that root folder as one component. Known original game files are protected; the protection list is not a full database of every game build.

**Simple Trainer settings.** The group moves `TrainerV.asi` and root-level `trainerv.ini` when present. Recent trainer versions can store their configuration in AppData; those external settings stay in place. Extra unrelated INI names are not assumed to belong to Simple Trainer. Refer to the [author's instructions](https://www.gta5-mods.com/scripts/simple-trainer-for-gtav).

**Moving/uninstalling the switcher.** Close the application before replacing its files. Settings are under `%LOCALAPPDATA%\SPARKYASHH\GTAVModSwitcher`; mod storage is beside the game directory. Restore disabled mods before deleting storage. If you relocate the application, recreate its shortcut.

**Online preparation.** Review all installed mods and original game files. The tool manages selected components only; launcher options and BattlEye settings are separate. An untouched external INI is not an ASI plugin; restoring original game archives requires your game tools/launcher rather than this switcher.

<a id="russian"></a>
## Русский

**Ошибка запуска.** Распакуйте готовый ZIP целиком и запускайте EXE вместе со служебными файлами. Отдельное сообщение укажет журнал в `%LOCALAPPDATA%\SPARKYASHH\GTAVModSwitcher\logs`. Журналы автоматически никуда не отправляются. Перед открытием окна EXE выполняет проверки на временных файлах; при ошибке запуск блокируется.

**Отказано в доступе.** Закройте GTA V, OpenIV и окна Проводника, работающие с этими папками. Проверьте права своей учётной записи Windows на папку GTA и её родительскую папку, где создаётся хранилище. Программа не завершает чужие процессы и не закрывает их дескрипторы. Права администратора автоматически не запрашиваются.

**Две копии файла.** Сравните папку игры и хранилище. После выбора нужной копии перенесите лишнюю в отдельную резервную папку. Программа отказывается объединять или перезаписывать обе копии.

**Операция прервалась.** Кнопка **«Восстановить»** возвращает состояние до прерванного переключения: в зависимости от операции это может включить или отключить моды. Если файлы есть в обеих папках либо отсутствуют в обеих, сначала устраните конфликт. Сохраните `operation.json`: удаление журнала не исправляет расположение файлов.

**Нет нужной группы.** Группы показывают файлы, найденные в GTA или в хранилище. После установки мода обновите список и проверьте новые группы. Свои файлы и папки в корне игры добавляйте явно. Для вложенных файлов выбирайте корневую папку целиком. Известные оригинальные файлы защищены; это не полная база всех сборок игры.

**Настройки Simple Trainer.** В группу входят `TrainerV.asi` и `trainerv.ini` в корне GTA, если они есть. Новые версии тренера могут хранить конфигурацию в AppData — она сохраняется на месте. Дополнительные INI с общими названиями автоматически не приписываются Simple Trainer. Подробнее — в [инструкции автора](https://www.gta5-mods.com/scripts/simple-trainer-for-gtav).

**Перенос или удаление переключателя.** Закройте программу перед заменой файлов. Настройки хранятся в `%LOCALAPPDATA%\SPARKYASHH\GTAVModSwitcher`, моды — рядом с GTA. Перед удалением хранилища верните отключённые моды. После переноса программы создайте ярлык заново.

**Подготовка к Online.** Проверьте установленные моды и оригинальные файлы игры. Переключатель управляет выбранными компонентами; параметры лаунчера и BattlEye настраиваются отдельно. Внешний INI сам по себе не является ASI-плагином; восстановление изменённых оригинальных архивов выполняется средствами игры/лаунчера.
