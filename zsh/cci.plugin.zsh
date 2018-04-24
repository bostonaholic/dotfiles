function cci() {
  set_env_var CIRCLECI_HOME $HOME'/code/circleci'
  #set_env_var CIRCLE_CONTAINER_IMAGE_URI "docker://circleci/build-image:trusty-654-3645de6"

  # JAVA
  set_env_var JAVA_HOME '/Library/Java/JavaVirtualMachines/jdk1.8.0_151.jdk/Contents/Home'

  cd $CIRCLECI_HOME

  # PWD
  show_env_var PWD
}

function graylog_connect () {
    ssh -f -N -L 9000:graylog-primary.infra.circleci.com:80 jump.circleci.com
}
