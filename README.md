# yazi-nofar — Yazi как основной файловый менеджер и файлпикер

Весь Yazi этой машины: конфиг файлового менеджера, отдельный конфиг
системного файлпикера (окна «Открыть» / «Сохранить» в Telegram, браузере,
Steam), ярлык и сервис «Показать в папке» вместо Dolphin. Восстанавливается
одной командой.

## Восстановить на новом компьютере

```
git clone https://github.com/PHONE1X/yazi-nofar ~/WORKSPACE/projects/yazi-nofar
cd ~/WORKSPACE/projects/yazi-nofar
./install.sh --deps        # пакеты (pacman + paru) и всё остальное
```

`./install.sh` без `--deps` — то же без пакетов. `./install.sh --uninstall` — снять.
Если `~/.config/yazi` уже есть настоящей папкой, скрипт её не тронет и скажет,
что перенести.

## Что где

| В репозитории | Куда ставится | Что это |
|---|---|---|
| `config/` | `~/.config/yazi` (ссылка) | файловый менеджер: клавиши, правила открытия, превью, плагины |
| `picker/` | `~/.config/yazi-picker` (ссылка) | файлпикер: свои `keymap.toml` и `init.lua`, остальное — ссылки на `config/` |
| `filepicker/` | `~/.config/xdg-desktop-portal-termfilechooser/` | обёртка портала, его конфиг, `hyprland-portals.conf`, юнит `steam-bus-bind` |
| `bin/yazi-open` | `~/.local/bin` | открыть Yazi в окне kitty на папке или файле |
| `bin/yazi-fm1` | `~/.local/bin` + `~/.local/share/dbus-1/services/` | D-Bus `org.freedesktop.FileManager1`: «Показать в папке» -> Yazi |
| `system/yazi.desktop.in` | `~/.local/share/applications/yazi.desktop` | ярлык; Yazi — программа по умолчанию для папок (`inode/directory`) |
| `fish/y.fish` | `~/.config/fish/functions/y.fish` (ссылка) | `y` в терминале: yazi, после выхода — `cd` в последнюю папку |

Конфиги стоят ссылками, поэтому всё, что меняется в самом yazi (попап `F`,
закладки, `ya pkg add`), сразу видно в `git status` — остаётся закоммитить.

## Файлпикер

Свой конфиг `~/.config/yazi-picker`: клавиши пикера не попадают в обычный yazi.
В шапке окна написано, что от тебя хотят и что жать.

| Клавиша | Что делает |
|---|---|
| Enter / l / → | папка — войти; файл — выбрать. При сохранении Enter на файле **спрашивает**, заменить ли его |
| s / Ctrl+S | «Сохранить» — сохранить в папку, где стоишь (спросит имя, предложит исходное); «Папка» — выбрать папку, где стоишь |
| Пробел | отметить файл (когда можно выбрать несколько) |
| q | отмена |
| `'` / `` ` ``, g p, M, T | закладки, телефон (KDE Connect), диски, превью — как в основном yazi |

Режим (`open` / `multi` / `dir` / `save`) выставляет `filepicker/yazi-wrapper.sh`
через `YAZI_PICK`; выбор пишет `config/plugins/picker.yazi`.

## Основной Yazi: что добавлено

* **Открытие файлов.** Enter/l — плагин `doc-open` (список «чем что открывать»
  правится попапом `F`). `o` / `O` («Открыть с помощью…») — правила
  `[open]` в `yazi.toml`. В yazi 26 путь подставляется как `%s`, старое `"$@"`
  отдавало программе пустой список — из-за этого «Открыть с помощью» не работало.
* **Превью**: картинки, видео, PDF — встроенные; архивы — `ouch`; markdown —
  `glow` (через `piper`).
* **Системный буфер** (плагин `ucp`): **Alt+C** — файлы в буфер как файлы
  (Ctrl+V в Telegram/браузере их прикрепит), **Alt+V** — вставить из буфера
  файлы, картинку (.png) или текст (новым файлом). `y` по-прежнему копирует путь
  текстом.
* **Мышью**: **Alt+D** — утащить выделенные файлы в другое окно,
  **Alt+I** — принять брошенные файлы в текущую папку (`kitten dnd` из kitty 0.50).
* **Google Drive** монтируется, когда заходишь в `~/Google Drive`
  (`plugins/gdrive-mount.yazi`, общий с файлпикером).

## Проверка

```
xdg-mime query default inode/directory          # yazi.desktop
busctl --user status org.freedesktop.FileManager1 | grep CommandLine   # yazi-fm1
yazi-open --dry-run ~/Downloads                 # команда, которой откроется окно
```

Файлпикер без окна (tmux вместо kitty): `TERMCMD=<скрипт, запускающий команду
в tmux> filepicker/yazi-wrapper.sh 0 0 1 /tmp/x/new.txt /tmp/out 0`, клавиши —
`tmux send-keys`, результат — в `/tmp/out`.

## История

* 13.11.2026 — из рабочего конфига вырезан FAR-режим (коммит `vendor` — копия
  до этого), файлпикер восстановлен (`FileChooser = termfilechooser`, `steam-bus-bind`).
* 21.11.2026 — `~/.config/yazi` стал ссылкой на этот репозиторий; отдельный
  конфиг файлпикера с подсказками и подтверждением перезаписи (до этого Enter
  на файле в окне «Сохранить» молча его затирал); Yazi — программа для папок и
  FileManager1 вместо Dolphin; исправлены правила открытия (`%s`).
