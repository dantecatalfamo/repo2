function repo {
    case $1 in
        cl*)
            repo-clone $@
            ;;
        cd)
            repo-cd $@
            ;;
        *)
            repo-zig $@
            ;;
    esac
}

function repo-clone {
    output=$(repo-zig clone ${@:2})

    if [ $? -eq 0 ]; then
        cd $output
    fi
}

function repo-cd {
    output=$(repo-zig cd ${@:2})

    if [ $? -eq 0 ]; then
        cd $output
    fi
}
