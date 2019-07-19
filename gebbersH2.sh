#! /usr/bin/env bash
gradle cleanAll
gradle load -Ptypes=seed,seed-initial,install
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbers,seed-initial-gebbers,install-gebbers components=gebbers
java -XX:+UseG1GC -jar moqui.war load types=johndoe-gebbers components=gebbers
java -XX:+UseG1GC -jar moqui.war load types=demo-gebbers components=gebbers
gradle runtime:component:gebbers:test
