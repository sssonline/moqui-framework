#! /usr/bin/env bash
gradle cleanAllButDb -Duser.dir=`pwd`
# CLRLIB MOQUI
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon,seed-gebbersWarehouse,seed-initial-gebbersWarehouse,install-gebbersWarehouse components=gebbers conf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=johndoe-gebbersWarehouse components=gebbers conf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=demo-gebbersWarehouse components=gebbers conf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
gradle runtime:component:gebbers:test -Pconf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
