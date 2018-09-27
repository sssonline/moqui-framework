#! /usr/bin/env bash
MEM=8192
RE='^[1-9][0-9]*$'
if [[ $1 =~ $RE && $1 -le 128 ]]; then
  let "MEM = $1 * 1024"
fi
java -server -XX:-OmitStackTraceInFastThrow -XX:+UseG1GC -Xmx${MEM}m -jar moqui.war
