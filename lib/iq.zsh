function colorize() { echo "$fg_bold[green]$1$fg[white]=`printenv $1`" }

function setter() {
  export $1=$2
  colorize $1
}

function tomcat_startup() { $CATALINA_HOME/bin/startup.sh }
function tomcat_shutdown() { $CATALINA_HOME/bin/shutdown.sh }
function tomcat_restart() {
  tomcat_shutdown
  sleep 5
  tomcat_startup
}

function solr_startup() {
  setter CATALINA_HOME $SOLR_HOME
  $CATALINA_HOME/bin/startup.sh
}

function solr_shutdown() { $SOLR_HOME/bin/shutdown.sh }

function iq() {
  cd ~/code/iqity

  # JAVA_HOME
  setter JAVA_HOME '/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home'
  setter JAVA_OPTS '-Xms512m -Xmx1024m -XX:PermSize=128m -XX:MaxPermSize=256m'

  # MYSQL
  setter MYSQL_HOME '/usr/local/Cellar/mysql/5.6.12'

  # MAVEN
  setter M2_HOME '/usr/share/maven'
  setter MAVEN_OPTS '-Xms512m -Xmx1g -XX:PermSize=512m -XX:MaxPermSize=1g'

  # APACHE TOMCAT
  setter CATALINA_HOME '/usr/local/bin/apache-tomcat-6.0.29'
  setter SOLR_HOME '/usr/local/bin/apache-tomcat-6.0.29-solr'
  setter CATALINA_OPTS '-server -d64 -Xms1g -Xmx2g -XX:MaxPermSize=1024m'

  # GROOVY
  # setter GROOVY_HOME '/usr/local/Cellar/groovy/2.1.5'

  # PATH
  export PATH=$MYSQL_HOME/bin:$M2_HOME/bin:$CATALINA_HOME/bin:$JAVA_HOME/bin:$GROOVY_HOME/bin:$PATH

  # PWD
  colorize PWD
}
