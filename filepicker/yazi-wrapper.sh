#!/usr/bin/env sh
# Обёртка Yazi для xdg-desktop-portal-termfilechooser.
#
# Скрипт вызывает сам портал, когда любое приложение просит системный диалог
# выбора файла. Задача обёртки - запустить Yazi в терминале и записать
# выбранные пути в файл "$out", который потом читает портал.
#
# Порядок аргументов задан порталом (man 5 xdg-desktop-portal-termfilechooser):
#   $1 multiple  - 0/1, разрешён ли выбор нескольких файлов
#   $2 directory - 0/1, выбирается каталог, а не файл
#   $3 save      - 0/1, режим сохранения файла
#   $4 path      - подсказанный приложением путь (файл или каталог)
#   $5 out       - файл, в который надо записать выбранные пути
#   $6 debug     - 0/1, включить трассировку

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

cmd="yazi"

# Признак режима файлпикера для конфига yazi (plugins/doc-open.yazi):
# в этом режиме Enter выбирает файл и закрывает yazi, а не открывает его
# портпротоном/редактором — иначе выбранный .exe улетает в PortProton,
# а Steam так и не получает путь.
YAZI_CHOOSER=1
export YAZI_CHOOSER
if [ "$directory" = "1" ]; then
    YAZI_CHOOSER_DIR=1
    export YAZI_CHOOSER_DIR
fi

# Заголовок окна зависит от режима, чтобы было понятно, чего от нас хотят.
if [ "$save" = "1" ]; then
    title="Сохранить файл - выберите файл для перезаписи"
elif [ "$directory" = "1" ]; then
    title="Выбор папки - откройте нужную и нажмите q"
elif [ "$multiple" = "1" ]; then
    title="Выбор файлов - пробел отмечает, Enter подтверждает"
else
    title="Выбор файла - Enter подтверждает, q отмена"
fi

# app-id фиксированный: по нему правило Hyprland делает окно плавающим.
# TERMCMD из конфига, если он задан, имеет приоритет.
termcmd="${TERMCMD:-kitty --app-id=termfilechooser --title=\"$title\"}"

if [ "$save" = "1" ]; then
    # Сохранение файла: портал заранее создал файл-заглушку по пути "$path",
    # пользователь выбирает его (или другой файл) для перезаписи.
    set -- --chooser-file="$out" "$path"
elif [ "$directory" = "1" ]; then
    # Выбор каталога: --cwd-file запоминает текущий каталог Yazi при выходе,
    # поэтому достаточно зайти в нужную папку и нажать q.
    set -- --chooser-file="$out" --cwd-file="$out"".1" "$path"
elif [ "$multiple" = "1" ]; then
    # Несколько файлов: отмечаем пробелом, подтверждаем Enter.
    set -- --chooser-file="$out" "$path"
else
    # Один файл.
    set -- --chooser-file="$out" "$path"
fi

# Собираем строку команды вручную, потому что терминал запускается через sh -c.
command="$termcmd $cmd"
for arg in "$@"; do
    # экранируем двойные кавычки внутри пути
    escaped=$(printf "%s" "$arg" | sed 's/"/\\"/g')
    command="$command \"$escaped\""
done

sh -c "$command"

if [ "$directory" = "1" ]; then
    # Если пользователь ничего не "открыл", а просто вышел из Yazi,
    # берём каталог из cwd-file как результат выбора.
    if [ ! -s "$out" ] && [ -s "$out"".1" ]; then
        cat "$out"".1" > "$out"
        rm "$out"".1"
    else
        rm -f "$out"".1"
    fi
fi
