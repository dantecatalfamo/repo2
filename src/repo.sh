function repo {
    case $1 in
        clone|cd)
            repo-cd $@
            ;;
        *)
            repo-zig $@
            ;;
    esac
}

function repo-cd {
    output=$(repo-zig $@)

    if [ $? -eq 0 ]; then
        cd $output
    fi
}
