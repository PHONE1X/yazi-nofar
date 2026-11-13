#!/usr/bin/env bash
# Установка форка yazi-nofar: команда `yz` (yazi без FAR-режима).
# Рабочий ~/.config/yazi не трогается. Снять: ./install.sh --uninstall
set -eu

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bindir="$HOME/.local/bin"
fishdir="$HOME/.config/fish/functions"

if [ "${1:-}" = "--uninstall" ]; then
    rm -f "$bindir/yz" "$fishdir/yz.fish"
    echo "yz удалён"
    exit 0
fi

chmod +x "$here/bin/yz"
mkdir -p "$bindir" "$fishdir"
ln -sfn "$here/bin/yz" "$bindir/yz"
install -m 644 "$here/fish/yz.fish" "$fishdir/yz.fish"

echo "готово:"
echo "  $bindir/yz"
echo "  $fishdir/yz.fish"
echo "конфиг без FAR-режима: $here/config"
