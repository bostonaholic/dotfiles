function colorize() {
  echo "$fg_bold[green]$1$fg[white]=$2"
}

function iq() {
  cd ~/code/iqity

  # JAVA_HOME
  export JAVA_HOME='/System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents/Home'
  colorize "JAVA_HOME" $JAVA_HOME

  # PWD
  export PATH=$JAVA_HOME:$PATH
  colorize "PWD" $PWD
}
