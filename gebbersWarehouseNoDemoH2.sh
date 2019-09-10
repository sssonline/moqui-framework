#! /usr/bin/env bash
gradle cleanAll
gradle load -Ptypes=seed,seed-initial,install
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon,seed-gebbersWarehouse,seed-initial-gebbersWarehouse,install-gebbersWarehouse components=gebbers,gebbersw
java -XX:+UseG1GC -jar moqui.war load types=johndoe-gebbersWarehouse components=gebbersw
#java -XX:+UseG1GC -jar moqui.war load types=demo-gebbersWarehouse components=gebbersw
#gradle runtime:component:gebbersw:test
