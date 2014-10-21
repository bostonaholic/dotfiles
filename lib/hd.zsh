function datomic_start() {
  pushd $DATOMIC_HOME
  ./bin/transactor -Xmx4g config/dev-transactor.properties
  popd
}

function datomic_console() {
  pushd $DATOMIC_HOME
  ./bin/console -p 4334 dev datomic:dev://localhost:4334/
  popd
}

function hd() {
  set_env_var HENDRICK_HOME $HOME'/code/Hendrick'
  cd $HENDRICK_HOME

  # JAVA
  set_env_var JAVA_HOME '/Library/Java/JavaVirtualMachines/jdk1.7.0_51.jdk/Contents/Home/'

  # DATOMIC
  set_env_var DATOMIC_HOME '/opt/datomic-pro-0.9.4815.12'
  alias ds=datomic_start

  # PATH
  export PATH=$DATOMIC_HOME/bin:$PATH

  # NOMAD_ENV
  set_env_var NOMAD_ENV 'dev'

  # PWD
  show_env_var PWD
}
