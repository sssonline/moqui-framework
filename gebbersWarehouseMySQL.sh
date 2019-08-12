#! /usr/bin/env bash
gradle cleanAllButDb
./cleanMySQL.sh
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon,seed-gebbersWarehouse,seed-initial-gebbersWarehouse,install-gebbersWarehouse components=gebbers conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=johndoe-gebbersWarehouse components=gebbers conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=demo-gebbersWarehouse components=gebbers conf=conf/MoquiDevConfMySQL.xml
gradle runtime:component:gebbers:test -Pconf=conf/MoquiDevConfMySQL.xml
