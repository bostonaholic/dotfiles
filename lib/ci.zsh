function ci() {
  set_env_var CIRCLECI_HOME $HOME'/code/circleci'
  cd $CIRCLECI_HOME

  # PWD
  show_env_var PWD
}