#!/usr/bin/env bash
# Установка «yazi как системный файлпикер» (xdg-desktop-portal-termfilechooser).
# Нужен sudo только для юнита steam-bus-bind (шина в песочницу Steam).
# Снять: ./install.sh --uninstall
set -eu

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
confdir="$HOME/.config/xdg-desktop-portal-termfilechooser"
portalconf="$HOME/.config/xdg-desktop-portal"
unitdir="$HOME/.config/systemd/user/xdg-desktop-portal-termfilechooser.service.d"

if [ "${1:-}" = "--uninstall" ]; then
    rm -f "$confdir/yazi-wrapper.sh" "$confdir/config"
    rm -f "$portalconf/hyprland-portals.conf"
    rm -f "$unitdir/env.conf"
    systemctl --user daemon-reload || true
    systemctl --user restart xdg-desktop-portal xdg-desktop-portal-termfilechooser || true
    sudo systemctl disable --now steam-bus-bind || true
    sudo rm -f /etc/systemd/system/steam-bus-bind.service /usr/local/bin/steam-bus-bind
    sudo systemctl daemon-reload || true
    echo "файлпикер снят"
    exit 0
fi

mkdir -p "$confdir" "$portalconf" "$unitdir"
install -m 755 "$here/yazi-wrapper.sh" "$confdir/yazi-wrapper.sh"
install -m 644 "$here/config" "$confdir/config"
install -m 644 "$here/hyprland-portals.conf" "$portalconf/hyprland-portals.conf"

# Портал запускается systemd --user и не получает WAYLAND_DISPLAY: без него kitty
# падает с «GLFW initialization failed», и файлпикер молча не открывается.
cat > "$unitdir/env.conf" <<'EOF'
[Service]
Environment=WAYLAND_DISPLAY=wayland-1
Environment=XDG_CURRENT_DESKTOP=Hyprland
EOF

# Шина D-Bus для Steam: steamwebhelper живёт в bwrap-песочнице pressure-vessel и
# стучится в /run/pressure-vessel/bus, которого Steam не создаёт.
sudo install -m 755 "$here/steam-bus-bind" /usr/local/bin/steam-bus-bind
sudo install -m 644 "$here/steam-bus-bind.service" /etc/systemd/system/steam-bus-bind.service
sudo systemctl daemon-reload
sudo systemctl enable --now steam-bus-bind

systemctl --user daemon-reload
systemctl --user restart xdg-desktop-portal-termfilechooser xdg-desktop-portal

echo "готово. Проверка (откроется окно yazi — это и есть тест):"
echo "  busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \\"
echo "    org.freedesktop.portal.FileChooser OpenFile ssa{sv} \"\" \"test\" 1 handle_token s t\$(date +%s)"
