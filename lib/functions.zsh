function show_env_var() { echo "$fg_bold[green]$1$fg[white]=`printenv $1`" }

function set_env_var() {
  export $1=$2
  show_env_var $1
}

