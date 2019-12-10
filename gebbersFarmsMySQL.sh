#! /usr/bin/env bash
gradle cleanAllButDb
./cleanMySQL.sh
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon,seed-gebbersFarms,seed-initial-gebbersFarms,install-gebbersFarms components=gebbers conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=johndoe-gebbersFarms components=gebbers conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=janedoe-gebbersFarms components=gebbers conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=demo-gebbersFarms components=gebbers conf=conf/MoquiDevConfMySQL.xml
gradle runtime:component:gebbers:test -Pconf=conf/MoquiDevConfMySQL.xml -Darg1=GebbersFarms
