function yz --description 'yazi без FAR-режима (форк yazi-nofar)'
    set --local home $HOME/WORKSPACE/projects/yazi-nofar
    set --local conf $home/config
    set --local cwd_file (mktemp -u)

    if not test -f $conf/keymap.toml
        echo "yz: нет конфига $conf" >&2
        return 1
    end

    set -lx YAZI_CONFIG_HOME $conf
    command yazi --cwd-file="$cwd_file" $argv

    if test -f "$cwd_file"
        set --local last (cat "$cwd_file")
        if test -n "$last" -a -d "$last"
            cd "$last"
        end
        rm -f "$cwd_file"
    end
end
