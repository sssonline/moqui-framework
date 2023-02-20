#! /usr/bin/env bash
gradle cleanAllButDb
./cleanMySQL.sh
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon,seed-gebbersSalary,seed-initial-gebbersSalary,install-gebbersSalary components=gebbers,gebberssal conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=johndoe-gebbersSalary components=gebberssal conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=janedoe-gebbersSalary components=gebberssal conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=demo-gebbersSalary components=gebberssal conf=conf/MoquiDevConfMySQL.xml
gradle runtime:component:gebberssal:test -Pconf=conf/MoquiDevConfMySQL.xml # -Darg1=GebbersSalary
