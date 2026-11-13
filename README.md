# yazi-nofar — мой конфиг yazi без FAR-режима

Форк рабочего `~/.config/yazi` (со всеми правками, включая `y` = копирование
путей в буфер обмена), из которого вырезано всё «фарное»:

* плагины `far-mode`, `far-menu`, `far-tree` и вторая раскладка `keymap-far.toml`;
* переключатель раскладки в попапе `F` (страница Startup settings) и Alt+M / `b f`;
* перезапуск процесса ради смены режима (вся возня с `YAZI_RESTART_FILE` /
  `YAZI_STATE_FILE` / `YAZI_KEYMAP_MODE` в fish-функции `y`).

Раскладка осталась одна — vim-подобная (`config/keymap.toml`). `far-bookmarks`
(закладки на `, ' и Alt+B) не тронут — это не FAR-режим, а просто список папок.

Сам бинарник yazi не пересобирается: FAR-режим живёт в конфиге, а не в
приложении, так что пересборка ничего бы не изменила.

## Файлпикер (yazi вместо системного диалога)

`filepicker/` — вся система «yazi как файлпикер»: обёртка
`yazi-wrapper.sh`, конфиг портала, `hyprland-portals.conf`
(`FileChooser = termfilechooser`), drop-in с `WAYLAND_DISPLAY` и юнит
`steam-bus-bind` (шина D-Bus в песочницу Steam).

```
filepicker/install.sh              # восстановить файлпикер (нужен sudo)
filepicker/install.sh --uninstall
```

13.11.2026 файлпикер не открывался из Steam: в `hyprland-portals.conf`
стоял бэкенд `kde` (юнит `plasma-xdg-desktop-portal-kde` замаскирован → портал
отвечал «unit is masked»), сама обёртка в `~/.config/xdg-desktop-portal-termfilechooser/`
отсутствовала (остался только `.bak`), а `/run/pressure-vessel` не существовал.
После восстановления: `FileChooser = termfilechooser`, обёртка на месте,
`steam-bus-bind` перезапущен.

## Перенос на рабочий конфиг

13.11.2026 этот конфиг перенесён в `~/.config/yazi` (старый с FAR — в бэкапе
`Gdrive:backups/2026-11-13-yazi-nofar/` и в коммите `vendor` этого репозитория),
fish-функция `y` упрощена: без переменных режима и без перезапуска процесса.

## Установка и запуск

```
./install.sh          # ставит команду yz (~/.local/bin/yz + fish-функцию), ~/.config/yazi не трогает
yz [путь]             # yazi на этом конфиге, каталог выхода подхватывается в fish
./install.sh --uninstall
```

Сделать форк основной командой `y`:

```
cd ~/.config/fish/functions
cp y.fish y.fish.old && cp ~/WORKSPACE/projects/yazi-nofar/fish/yz.fish y.fish
```

## Что проверено

* запускается, ошибок в `~/.local/state/yazi/yazi.log` нет;
* `y` = пути в буфер (выделение или подсвеченный файл), файлы не открываются;
* попап `F` (Openers/Startup) открывается без строки «Keymap mode»;
* dual-pane `b t` включается/выключается;
* скорость старта не изменилась: 260 мс было / 259 мс стало (медиана 7 замеров) —
  far-плагины на запуск не влияли, выигрыш только в объёме кода и в отсутствии
  путаницы раскладок.
