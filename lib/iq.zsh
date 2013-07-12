function colorize() { echo "$fg_bold[green]$1$fg[white]=$2" }

function tomcat_startup() { $CATALINA_HOME/bin/startup.sh }
function tomcat_shutdown() { $CATALINA_HOME/bin/shutdown.sh }
function tomcat_restart() {
  tomcat_shutdown
  sleep 5
  tomcat_startup
}

function solr_startup() {
  CATALINA_HOME=$SOLR_HOME
  colorize "CATALINA_HOME" $CATALINA_HOME
  $SOLR_HOME/bin/startup.sh
}

function solr_shutdown() { $SOLR_HOME/bin/shutdown.sh }

function iq() {
  cd ~/code/iqity

  # JAVA_HOME
  export JAVA_HOME='/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home'
  export JAVA_OPTS='-Xms512m -Xmx1024m -XX:PermSize=128m -XX:MaxPermSize=256m'
  colorize "JAVA_HOME" $JAVA_HOME
  colorize "JAVA_OPTS" $JAVA_OPTS

  # MYSQL
  export MYSQL_HOME='/usr/local/Cellar/mysql/5.6.12'
  colorize "MYSQL_HOME" $MYSQL_HOME

  # MAVEN
  export M2_HOME='/usr/share/maven'
  export MAVEN_OPTS='-Xms512m -Xmx1g -XX:PermSize=512m -XX:MaxPermSize=1g'
  colorize "M2_HOME" $M2_HOME
  colorize "MAVEN_OPTS" $MAVEN_OPTS

  # APACHE TOMCAT
  export CATALINA_HOME='/usr/local/bin/apache-tomcat-6.0.29'
  export SOLR_HOME='/usr/local/bin/apache-tomcat-6.0.29-solr'
  export CATALINA_OPTS='-server -d64 -Xms1g -Xmx2g -XX:MaxPermSize=1024m'
  colorize "CATALINA_HOME" $CATALINA_HOME
  colorize "CATALINA_OPTS" $CATALINA_OPTS
  colorize "SOLR_HOME" $SOLR_HOME

  # GROOVY
  # export GROOVY_HOME='/usr/local/Cellar/groovy/2.1.5'
  # colorize "GROOVY_HOME" $GROOVY_HOME

  # PATH
  export PATH=$MYSQL_HOME/bin:$M2_HOME/bin:$CATALINA_HOME/bin:$JAVA_HOME/bin:$GROOVY_HOME/bin:$PATH

  # PWD
  colorize "PWD" $PWD
}
