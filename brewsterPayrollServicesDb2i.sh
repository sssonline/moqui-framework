#! /usr/bin/env bash
gradle cleanAllButDb -Duser.dir=`pwd`
# CLRLIB MOQUI
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfDb2iPayrollGb.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon components=gebbers conf=conf/MoquiDevConfDb2iPayrollGb.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=seed-brewsterPayrollServices,seed-initial-brewsterPayrollServices,install-brewsterPayrollServices components=gebbersb conf=conf/MoquiDevConfDb2iPayrollGb.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=johndoe-brewsterPayrollServices components=gebbersb conf=conf/MoquiDevConfDb2iPayrollGb.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=janedoe-brewsterPayrollServices components=gebbersb conf=conf/MoquiDevConfDb2iPayrollGb.xml -Duser.dir=`pwd`
java -XX:+UseG1GC -jar moqui.war load types=demo-brewsterPayrollServices components=gebbersb conf=conf/MoquiDevConfDb2iPayrollGb.xml -Duser.dir=`pwd`
gradle runtime:component:gebbersb:test -Pconf=conf/MoquiDevConfDb2iPayrollGb.xml -Duser.dir=`pwd` # -Darg1=brewsterPayrollServices
