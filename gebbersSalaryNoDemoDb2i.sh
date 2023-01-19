#! /usr/bin/env bash
gradle cleanAllButDb -Duser.dir=`pwd`
# CLRLIB MOQUI
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfDb2iPayrollGs.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon components=gebbers conf=conf/MoquiDevConfDb2iPayrollGs.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersSalary,seed-initial-gebbersSalary,install-gebbersSalary components=gebberssal conf=conf/MoquiDevConfDb2iPayrollGs.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=johndoe-gebbersSalary components=gebberssal conf=conf/MoquiDevConfDb2iPayrollGs.xml -Duser.dir=`pwd`
#java -XX:+UseG1GC -jar moqui.war load types=demo-gebbersSalary components=gebberssal conf=conf/MoquiDevConfDb2iPayrollGs.xml -Duser.dir=`pwd`
#gradle runtime:component:gebberssal:test -Pconf=conf/MoquiDevConfDb2iPayrollGs.xml -Duser.dir=`pwd`
