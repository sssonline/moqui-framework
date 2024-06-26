#! /usr/bin/env bash
MEM=16384
RE='^[1-9][0-9]*$'
if [[ $1 =~ $RE && $1 -le 128 ]]; then
  let "MEM = $1 * 1024"
fi
#java -server -Djava.awt.headless=true -XX:-OmitStackTraceInFastThrow -XX:+UseG1GC -Xmx${MEM}m -jar moqui.war conf=conf/MoquiProductionConfDb2iPayrollGs.xml
java -Djava.awt.headless=true -Dcom.ibm.jsse2.overrideDefaultTLS=true -XX:-OmitStackTraceInFastThrow -XX:+UseG1GC -Xmx${MEM}m -jar moqui.war conf=conf/MoquiProductionConfDb2iPayrollGs.xml port=8083
