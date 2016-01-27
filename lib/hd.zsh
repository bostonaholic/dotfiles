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

function datomic_log() {
  pushd $DATOMIC_HOME/log
  tail -f `ls -tr | tail -n 1`
  popd
}

function hd() {
  set_env_var HENDRICK_HOME $HOME'/code/Hendrick'
  cd $HENDRICK_HOME

  # JAVA
  set_env_var JAVA_HOME '/Library/Java/JavaVirtualMachines/jdk1.8.0_66.jdk/Contents/Home'

  # DATOMIC
  set_env_var DATOMIC_HOME '/opt/datomic-pro-0.9.5327'
  alias ds=datomic_start
  alias dl=datomic_log

  # PATH
  export PATH=$DATOMIC_HOME/bin:$JAVA_HOME/bin:$PATH

  # NOMAD_ENV
  set_env_var NOMAD_ENV 'dev'

  # PWD
  show_env_var PWD
}
