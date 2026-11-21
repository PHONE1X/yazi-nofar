#!/usr/bin/env sh
# Обёртка Yazi для xdg-desktop-portal-termfilechooser.
#
# Портал зовёт её, когда приложение просит системный диалог «Открыть» или
# «Сохранить». Она запускает kitty с yazi на ОТДЕЛЬНОМ конфиге
# ~/.config/yazi-picker (свои клавиши и подсказка в шапке) и ждёт, пока yazi
# закроется. Выбранные пути пишутся в "$out", его читает портал; нет файла —
# значит «Отмена».
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

# Режим и куда писать результат читают picker/init.lua и plugins/picker.yazi.
YAZI_CONFIG_HOME="${YAZI_PICKER_CONFIG:-$HOME/.config/yazi-picker}"
YAZI_PICK_OUT="$out"
export YAZI_CONFIG_HOME YAZI_PICK_OUT

if [ "$save" = "1" ]; then
    YAZI_PICK=save
elif [ "$directory" = "1" ]; then
    YAZI_PICK=dir
elif [ "$multiple" = "1" ]; then
    YAZI_PICK=multi
else
    YAZI_PICK=open
fi
export YAZI_PICK

start="$path"
if [ "$YAZI_PICK" = "save" ]; then
    # Приложение предлагает папку/имя. Если такой файл уже есть, курсор встанет
    # на него; если нет — откроется его папка, имя спросим при нажатии s.
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

# app-id фиксированный: по нему правило Hyprland делает окно плавающим.
termcmd="${TERMCMD:-kitty --app-id=termfilechooser --title=$(quote "$title")}"

sh -c "$termcmd yazi --chooser-file=$(quote "$out") $(quote "$start")"
