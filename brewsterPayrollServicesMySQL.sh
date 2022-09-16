#! /usr/bin/env bash
gradle cleanAllButDb
./cleanMySQL.sh
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon,seed-brewsterPayrollServices,seed-initial-brewsterPayrollServices,install-brewsterPayrollServices components=gebbers,gebbersb conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=johndoe-brewsterPayrollServices components=gebbersb conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=janedoe-brewsterPayrollServices components=gebbersb conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=demo-brewsterPayrollServices components=gebbersb conf=conf/MoquiDevConfMySQL.xml
gradle runtime:component:gebbersb:test -Pconf=conf/MoquiDevConfMySQL.xml # -Darg1=brewsterPayrollServices
