#!/usr/bin/env sh
# Обёртка Yazi для xdg-desktop-portal-termfilechooser.
#
# Портал зовёт её, когда приложение просит системный диалог «Открыть» или
# «Сохранить». Она запускает kitty с обычным yazi (конфиг тот же,
# ~/.config/yazi) и переменными YAZI_PICK*: по ним plugins/picker.yazi
# включает поведение пикера и подсказку в шапке. Выбранные пути пишутся в
# "$out", его читает портал; нет файла — значит «Отмена».
#
# Аргументы задаёт портал (man 5 xdg-desktop-portal-termfilechooser):
#   $1 multiple  - 0/1, можно выбрать несколько файлов
#   $2 directory - 0/1, выбирается папка
#   $3 save      - 0/1, сохранение файла
#   $4 path      - предложенный приложением путь (папка или файл)
#   $5 out       - куда записать выбранные пути
#   $6 debug     - 0/1, трассировка
# Дальше портал добавляет TERMCMD аргументами — не используем, берём $TERMCMD.

multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"
debug="$6"

set -e

if [ "$debug" = "1" ]; then
    set -x
fi

if [ "$save" = "1" ]; then
    YAZI_PICK=save
elif [ "$directory" = "1" ]; then
    YAZI_PICK=dir
elif [ "$multiple" = "1" ]; then
    YAZI_PICK=multi
else
    YAZI_PICK=open
fi
YAZI_PICK_OUT="$out"
export YAZI_PICK YAZI_PICK_OUT

start="$path"
if [ "$YAZI_PICK" = "save" ]; then
    # Приложение предлагает папку и имя. Есть такой файл — курсор встанет на
    # него, нет — откроется его папка. Enter сохранит в ту папку, где стоишь.
    YAZI_PICK_NAME=$(basename -- "$path")
    export YAZI_PICK_NAME
    if [ ! -e "$path" ]; then
        start=$(dirname -- "$path")
    fi
fi
if [ -z "$start" ] || [ ! -e "$start" ]; then
    start="$HOME"
fi

case "$YAZI_PICK" in
    save)  title="Сохранить: $YAZI_PICK_NAME" ;;
    dir)   title="Выбор папки" ;;
    multi) title="Выбор файлов" ;;
    *)     title="Выбор файла" ;;
esac

# Старый файл результата не должен сойти за выбор.
rm -f -- "$out"

# Терминал запускается через sh -c, поэтому аргументы экранируем сами.
quote() {
    printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

# --chooser-file только для «Открыть»: там выбор пишет встроенный open yazi.
# В «Сохранить» и «Папка» результат пишет plugins/picker.yazi, а без
# chooser-file случайное o/O на файле просто откроет его, а не затрёт.
chooser=""
case "$YAZI_PICK" in
    open|multi) chooser="--chooser-file=$(quote "$out")" ;;
esac

# app-id фиксированный: по нему правило Hyprland делает окно плавающим.
termcmd="${TERMCMD:-kitty --app-id=termfilechooser --title=$(quote "$title")}"

sh -c "$termcmd yazi $chooser $(quote "$start")"
