#! /usr/bin/env bash
gradle cleanAll
gradle load -Ptypes=seed,seed-initial,install
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersFarms,seed-initial-gebbersFarms,install-gebbersFarms components=gebbers
java -XX:+UseG1GC -jar moqui.war load types=johndoe-gebbersFarms components=gebbers
#java -XX:+UseG1GC -jar moqui.war load types=demo-gebbersFarms components=gebbers
#gradle runtime:component:gebbers:test
