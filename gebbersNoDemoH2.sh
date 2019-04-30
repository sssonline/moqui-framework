#! /usr/bin/env bash
gradle cleanAll
gradle load -Ptypes=seed,seed-initial,install
java -XX:+UseG1GC -jar moqui.war load types=johndoe components=gebbers
#java -XX:+UseG1GC -jar moqui.war load types=demo components=gebbers
#gradle runtime:component:gebbers:test
