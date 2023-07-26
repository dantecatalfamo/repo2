function repo {
    case $1 in
        clone|cd|new)
            repo-cd $@
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
