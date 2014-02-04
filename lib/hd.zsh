function datomic_start() {
  cd $DATOMIC_HOME
  ./bin/transactor -Xmx4g config/immutant.properties
}

function hd() {
  set_env_var HENDRICK_HOME $HOME'/code/hendrick'
  cd $HENDRICK_HOME

  # JAVA
  set_env_var JAVA_HOME '/Library/Java/JavaVirtualMachines/jdk1.7.0_51.jdk/Contents/Home/'

  # DATOMIC
  set_env_var DATOMIC_HOME '/opt/datomic-pro-0.9.4470'

  # PATH
  export PATH=$DATOMIC_HOME/bin:$PATH

  # PWD
  show_env_var PWD
}
