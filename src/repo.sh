function repo {
    case $1 in
        clone|cd|new|root)
            repo-cd $@
            ;;
        reload)
            repo-reload
            ;;
        *)
            repo-zig $@
            ;;
    esac
}

function repo-cd {
    output="$(repo-zig $@)"
    ret=$?

    if [ $ret -eq 0 ]; then
        cd "$output"
    else
        return $ret
    fi
}

function repo-reload {
    eval "$(repo-zig shell)"
}

function _repo_completions {
    if [ "${#COMP_WORDS[@]}" -eq 2 ]; then
        COMPREPLY=($(compgen -W "cd clone help shell env ls new root reload" "${COMP_WORDS[1]}"))
        return;
    fi

    if [ "${#COMP_WORDS[@]}" -eq 3 ] && [ "${COMP_WORDS[1]}" == "cd" ]; then
        local only_slashes="${COMP_WORDS[2]//[^\/]}"
        local num_slashes="${#only_slashes}"
        if [ $num_slashes -lt 2 ]; then
            compopt -o nospace
            COMPREPLY=($(repo cd && compgen -d -S / "${COMP_WORDS[2]}"))
        else
            COMPREPLY=($(repo cd && compgen -d "${COMP_WORDS[2]}"))
        fi

    else
        echo "NOT IT ${COMP_WORDS[1]}"
    fi
}

complete -F _repo_completions repo
