#! /usr/bin/env bash
gradle cleanAll
gradle load -Ptypes=seed,seed-initial,install
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon,seed-gebbersSalary,seed-initial-gebbersSalary,install-gebbersSalary components=gebbers,gebberssal
java -XX:+UseG1GC -jar moqui.war load types=johndoe-gebbersSalary components=gebberssal
#java -XX:+UseG1GC -jar moqui.war load types=demo-gebbersSalary components=gebberssal
#gradle runtime:component:gebberssal:test
