function y --description 'yazi (конфиг без FAR-режима)'
    set --local cwd_file (mktemp -u)

    command yazi --cwd-file="$cwd_file" $argv

    if test -f "$cwd_file"
        set --local last (cat "$cwd_file")
        if test -n "$last" -a -d "$last"
            cd "$last"
        end
        rm -f "$cwd_file"
    end
end
