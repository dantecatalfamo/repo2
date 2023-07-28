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
    output=$(repo-zig $@)
    ret=$?

    if [ $ret -eq 0 ]; then
        cd $output
    else
        return $ret
    fi
}

function repo-reload {
    eval "$(repo-zig shell)"
}
