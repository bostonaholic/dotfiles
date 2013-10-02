function tomcat_startup() { $CATALINA_HOME/bin/startup.sh }
function tomcat_shutdown() { $CATALINA_HOME/bin/shutdown.sh }
function tomcat_restart() {
  tomcat_shutdown
  sleep 5
  tomcat_startup
}

function solr_startup() {
  set_env_var CATALINA_HOME $SOLR_HOME
  $CATALINA_HOME/bin/startup.sh
}

function solr_shutdown() {
  $CATALINA_HOME/bin/shutdown.sh
  set_env_var CATALINA_HOME $ORIGINAL_CATALINA_HOME
}

function solr_restart() {
  solr_shutdown
  sleep 5
  solr_startup
}

function gatling() {
  $GATLING_HOME/bin/recorder.sh &
}

function iq() {
  set_env_var IQ_HOME $HOME'/code/iqity'
  cd $IQ_HOME

  # JAVA
  set_env_var JAVA_HOME '/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home'
  set_env_var JAVA_OPTS '-Xms512m -Xmx1024m -XX:PermSize=128m -XX:MaxPermSize=256m'

  # MYSQL
  set_env_var MYSQL_HOME '/usr/local/Cellar/mysql/5.6.12'
  set_env_var MYSQL_CONFIG "$MYSQL_HOME/my.cnf"

  # MAVEN
  set_env_var M2_HOME '/usr/share/maven'
  set_env_var MAVEN_OPTS '-Xms512m -Xmx1g -XX:PermSize=512m -XX:MaxPermSize=1g'

  # APACHE TOMCAT
  set_env_var CATALINA_HOME '/usr/local/bin/apache-tomcat-6.0.29'
  export ORIGINAL_CATALINA_HOME=$CATALINA_HOME
  set_env_var SOLR_HOME '/usr/local/bin/apache-tomcat-6.0.29-solr'
  set_env_var CATALINA_OPTS '-server -d64 -Xms1g -Xmx2g -XX:MaxPermSize=1024m'

  # GROOVY
  # set_env_var GROOVY_HOME '/usr/local/Cellar/groovy/2.1.5'

  # SCALA
  set_env_var SCALA_HOME "/opt/scala-2.9.3"
  set_env_var GATLING_HOME "/opt/gatling-charts-highcharts-1.5.2"

  # PATH
  export PATH=$MYSQL_HOME/bin:$M2_HOME/bin:$CATALINA_HOME/bin:$JAVA_HOME/bin:$SCALA_HOME/bin:$PATH

  # PWD
  show_env_var PWD
}

function iq_repos() { ssh git@git.iq-ity.org }

function iq_import() {
  mysql -u root cls -p < $IQ_HOME/lms-db/cls-schema/src/main/helper-scripts/development_school_data.sql
  if [ $? -eq 0 ]
  then
    echo "Success!"
  else
    echo "Failure..."
  fi
}

alias mvn_phudson='mvn clean install -Phudson && mvn install -PjasmineDesktop && mvn install -PjasmineResponsive'
