#! /usr/bin/env bash
gradle cleanAllButDb
./cleanMySQL.sh
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfMySQL.xml
java -jar moqui.war load types=demo components=webroot,gebbers conf=conf/MoquiDevConfMySQL.xml
gradle runtime:component:gebbers:test -Pconf=conf/MoquiDevConfMySQL.xml
