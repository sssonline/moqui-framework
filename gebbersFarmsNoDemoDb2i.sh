#! /usr/bin/env bash
gradle cleanAllButDb -Duser.dir=`pwd`
# CLRLIB MOQUI
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfDb2iPayrollGf.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon,seed-gebbersFarms,seed-initial-gebbersFarms,install-gebbersFarms components=gebbers conf=conf/MoquiDevConfDb2iPayrollGf.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=johndoe-gebbersFarms components=gebbers conf=conf/MoquiDevConfDb2iPayrollGf.xml -Duser.dir=`pwd`
#java -XX:+UseG1GC -jar moqui.war load types=demo-gebbersFarms components=gebbers conf=conf/MoquiDevConfDb2iPayrollGf.xml -Duser.dir=`pwd`
#gradle runtime:component:gebbers:test -Pconf=conf/MoquiDevConfDb2iPayrollGf.xml -Duser.dir=`pwd`
