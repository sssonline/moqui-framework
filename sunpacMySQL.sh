#! /usr/bin/env bash
gradle cleanAllButDb
./cleanMySQL.sh
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=johndoe,demo components=sunpac conf=conf/MoquiDevConfMySQL.xml
gradle runtime:component:sunpac:test -Pconf=conf/MoquiDevConfMySQL.xml
