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
    repo=$2
    if [ x$repo == x ];then
        echo "Repo required"
        return
    fi

    echo "Cloning ${repo}"
    output=$(repo-zig clone $repo)
    ret=$?

    if [ $ret -eq 0 ]; then
        cd $output
    elif [ $ret -eq 2 ]; then
        echo "Project already cloned"
    else
        echo "Error cloning project"
    fi
}

function repo-cd {
    search=$2

    output=$(repo-zig cd $search)

    if [ $? -eq 0 ]; then
        cd $output
    else
        echo "Error selecting project directory"
    fi
}
