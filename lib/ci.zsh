function ci() {
  set_env_var CIRCLECI_HOME $HOME'/code/circleci'
  set_env_var CIRCLE_CONTAINER_IMAGE_URI "docker://circleci/build-image:trusty-654-3645de6"

  cd $CIRCLECI_HOME

  # PWD
  show_env_var PWD
}
