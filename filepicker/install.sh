#!/usr/bin/env bash
# Yazi как системный файлпикер (xdg-desktop-portal-termfilechooser).
# Обёртка и конфиг портала ставятся ссылками на этот репозиторий, правки
# в репо сразу работают. sudo нужен только для юнита steam-bus-bind (шина
# в песочницу Steam), и только если он ещё не стоит.
# Снять: ./install.sh --uninstall
set -eu

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
confdir="$cfg/xdg-desktop-portal-termfilechooser"
portalconf="$cfg/xdg-desktop-portal"
unitdir="$cfg/systemd/user/xdg-desktop-portal-termfilechooser.service.d"

if [ "${1:-}" = "--uninstall" ]; then
    rm -f "$confdir/yazi-wrapper.sh" "$confdir/config"
    rm -f "$portalconf/hyprland-portals.conf"
    rm -f "$unitdir/env.conf"
    systemctl --user daemon-reload || true
    systemctl --user restart xdg-desktop-portal-termfilechooser xdg-desktop-portal || true
    sudo systemctl disable --now steam-bus-bind || true
    sudo rm -f /etc/systemd/system/steam-bus-bind.service /usr/local/bin/steam-bus-bind
    sudo systemctl daemon-reload || true
    echo "файлпикер снят"
    exit 0
fi

changed=0

# ссылка dst -> src (старая копия на месте заменяется); если содержимое
# поменялось — порталы надо перезапустить
put_link() {
    local src="$1" dst="$2"
    if [ "$(readlink -- "$dst" 2>/dev/null)" = "$src" ]; then
        return 0
    fi
    cmp -s -- "$src" "$dst" || changed=1
    ln -sfn -- "$src" "$dst"
}

mkdir -p "$confdir" "$portalconf" "$unitdir"
chmod +x "$here/yazi-wrapper.sh"
# обёртку портал читает при каждом диалоге — перезапуск ради неё не нужен
ln -sfn -- "$here/yazi-wrapper.sh" "$confdir/yazi-wrapper.sh"
put_link "$here/config" "$confdir/config"
put_link "$here/hyprland-portals.conf" "$portalconf/hyprland-portals.conf"

# Портал запускается systemd --user и не получает WAYLAND_DISPLAY: без него kitty
# падает с «GLFW initialization failed», и файлпикер молча не открывается.
envconf="$(mktemp)"
cat > "$envconf" <<'EOF'
[Service]
# Портал запускается systemd --user и не получает графическое окружение сессии:
# без WAYLAND_DISPLAY kitty (а значит и Yazi) падает на "GLFW initialization failed".
Environment=WAYLAND_DISPLAY=wayland-1
Environment=XDG_CURRENT_DESKTOP=Hyprland
EOF
if ! cmp -s "$envconf" "$unitdir/env.conf"; then
    install -m 644 "$envconf" "$unitdir/env.conf"
    changed=1
fi
rm -f "$envconf"

# Шина D-Bus для Steam: steamwebhelper живёт в bwrap-песочнице pressure-vessel и
# стучится в /run/pressure-vessel/bus, которого Steam не создаёт.
if ! cmp -s "$here/steam-bus-bind" /usr/local/bin/steam-bus-bind \
    || ! systemctl is-enabled --quiet steam-bus-bind 2>/dev/null; then
    sudo install -m 755 "$here/steam-bus-bind" /usr/local/bin/steam-bus-bind
    sudo install -m 644 "$here/steam-bus-bind.service" /etc/systemd/system/steam-bus-bind.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now steam-bus-bind
fi

# Обёртку портал читает заново при каждом диалоге; перезапуск нужен, только
# если поменялись его конфиг, portals.conf или drop-in.
if [ "$changed" = 1 ]; then
    systemctl --user daemon-reload
    systemctl --user restart xdg-desktop-portal-termfilechooser xdg-desktop-portal
    echo "файлпикер: порталы перезапущены"
fi

echo "файлпикер готов. Проверка (откроется окно yazi — это и есть тест):"
echo "  busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \\"
echo "    org.freedesktop.portal.FileChooser SaveFile ssa{sv} \"\" \"test\" 1 current_name v s test.txt"
