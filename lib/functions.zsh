function show_env_var() { echo "$1=`printenv $1`" }

function set_env_var() {
  export $1=$2
  show_env_var $1
}
