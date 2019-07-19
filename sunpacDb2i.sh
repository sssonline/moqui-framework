#! /usr/bin/env bash
gradle cleanAllButDb -Duser.dir=`pwd`
# CLRLIB MOQUI
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=seed-sunpac,seed-initial-sunpac,install-sunpac components=sunpac conf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=johndoe-sunpac components=sunpac conf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=demo-sunpac components=sunpac conf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
gradle runtime:component:sunpac:test -Pconf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
