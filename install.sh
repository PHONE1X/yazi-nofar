#!/usr/bin/env bash
# Yazi — основной файловый менеджер и системный файлпикер. Восстановление на
# любом компьютере с Arch/CachyOS + Hyprland + kitty:
#
#   git clone https://github.com/PHONE1X/yazi-nofar ~/WORKSPACE/projects/yazi-nofar
#   cd ~/WORKSPACE/projects/yazi-nofar
#   ./install.sh --deps      # пакеты (pacman + paru), конфиги, ярлыки, файлпикер
#   ./install.sh             # то же без установки пакетов
#   ./install.sh --uninstall
#
# Конфиги ставятся ССЫЛКАМИ на этот репозиторий: ~/.config/yazi -> config/,
# ~/.config/yazi-picker -> picker/. Всё, что меняется в yazi (попап F,
# закладки, ya pkg), сразу видно в `git status` — останется закоммитить.
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
bin="$HOME/.local/bin"

PACMAN_DEPS=(
    yazi kitty fd ripgrep fzf zoxide jq 7zip poppler ffmpeg imagemagick resvg
    ouch glow wl-clipboard trash-cli udisks2 python-gobject
    xdg-desktop-portal xdg-desktop-portal-hyprland
    neovim mpv haruna gwenview okular libreoffice-fresh
)
AUR_DEPS=(xdg-desktop-portal-termfilechooser-hunkyburrito-git)

say() { printf '\033[1m%s\033[0m\n' "$*"; }

skipped=()

# ссылка dst -> src. Настоящий каталог/файл на месте не трогаем (кроме файла,
# совпадающего с репозиторием) — пусть человек сам решит, куда его деть.
link() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] && ! [ -L "$dst" ]; then
        if [ -f "$dst" ] && cmp -s -- "$src" "$dst"; then
            rm -f -- "$dst"
        else
            echo "!! $dst уже есть и это не ссылка — пропускаю"
            skipped+=("$dst")
            return 0
        fi
    fi
    mkdir -p -- "$(dirname -- "$dst")"
    ln -sfn -- "$src" "$dst"
    echo "   $dst -> $src"
}

render() {
    local src="$1" dst="$2"
    mkdir -p -- "$(dirname -- "$dst")"
    sed "s|@BIN@|$bin|g" "$src" > "$dst"
    echo "   $dst"
}

uninstall() {
    for l in "$cfg/yazi" "$cfg/yazi-picker" "$bin/yazi-open" "$bin/yazi-fm1" \
             "$cfg/fish/functions/y.fish"; do
        [ -L "$l" ] && rm -f -- "$l" && echo "   убрано $l"
    done
    rm -f "$data/applications/yazi.desktop" \
          "$data/dbus-1/services/org.freedesktop.FileManager1.service"
    "$here/filepicker/install.sh" --uninstall
    echo "Папки снова откроет программа по умолчанию из ~/.config/mimeapps.list —"
    echo "поправь строку inode/directory, если нужно."
}

if [ "${1:-}" = "--uninstall" ]; then
    uninstall
    exit 0
fi

if [ "${1:-}" = "--deps" ]; then
    say "Пакеты"
    sudo pacman -S --needed "${PACMAN_DEPS[@]}"
    if command -v paru >/dev/null; then
        paru -S --needed "${AUR_DEPS[@]}"
    elif command -v yay >/dev/null; then
        yay -S --needed "${AUR_DEPS[@]}"
    else
        echo "!! нет paru/yay — поставь из AUR: ${AUR_DEPS[*]}"
    fi
fi

say "Конфиги yazi"
link "$here/config" "$cfg/yazi"
link "$here/picker" "$cfg/yazi-picker"
link "$here/fish/y.fish" "$cfg/fish/functions/y.fish"

say "Команды yazi-open и yazi-fm1"
chmod +x "$here/bin/yazi-open" "$here/bin/yazi-fm1"
link "$here/bin/yazi-open" "$bin/yazi-open"
link "$here/bin/yazi-fm1" "$bin/yazi-fm1"

say "Yazi — программа для папок (xdg-open, «Открыть папку»)"
render "$here/system/yazi.desktop.in" "$data/applications/yazi.desktop"
command -v update-desktop-database >/dev/null && update-desktop-database "$data/applications" || true
xdg-mime default yazi.desktop inode/directory
echo "   inode/directory -> $(xdg-mime query default inode/directory)"

say "«Показать в папке» (D-Bus org.freedesktop.FileManager1) -> Yazi вместо Dolphin"
render "$here/system/org.freedesktop.FileManager1.service.in" \
    "$data/dbus-1/services/org.freedesktop.FileManager1.service"
busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig >/dev/null 2>&1 || true

say "Файлпикер"
"$here/filepicker/install.sh"

if [ "${#skipped[@]}" -gt 0 ]; then
    say "Готово, но пропущено (на месте свои файлы):"
    printf '   %s\n' "${skipped[@]}"
    echo "Перенеси их в бэкап и запусти ./install.sh ещё раз."
    exit 2
fi
say "Готово."
