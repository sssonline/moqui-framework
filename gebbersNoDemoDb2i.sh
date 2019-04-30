#! /usr/bin/env bash
gradle cleanAllButDb -Duser.dir=`pwd`
# CLRLIB MOQUI
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=johndoe components=gebbers conf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
#gradle runtime:component:gebbers:test -Pconf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
