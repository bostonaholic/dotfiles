function show_env_var() { echo "$1=`printenv $1`" }

function set_env_var() {
    export $1=$2
    show_env_var $1
}

function ask() {
    local f=$1

    read -p "Do you want to call '$f'? (y/n) "
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        eval $f
    fi
}
