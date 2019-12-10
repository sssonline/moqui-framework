#! /usr/bin/env bash
gradle cleanAll
# See build.gradle to see how it loads this seed data:
gradle load -Ptypes=seed,seed-initial,install
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon,seed-gebbersFarms,seed-initial-gebbersFarms,install-gebbersFarms components=gebbers
java -XX:+UseG1GC -jar moqui.war load types=johndoe-gebbersFarms components=gebbers
java -XX:+UseG1GC -jar moqui.war load types=janedoe-gebbersFarms components=gebbers
java -XX:+UseG1GC -jar moqui.war load types=demo-gebbersFarms components=gebbers
gradle runtime:component:gebbers:test -Darg1=GebbersFarms
