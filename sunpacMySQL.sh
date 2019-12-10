#! /usr/bin/env bash
gradle cleanAllButDb
./cleanMySQL.sh
gradle load -Ptypes=seed,seed-initial,install -Pconf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=seed-sunpac,seed-initial-sunpac,install-sunpac components=sunpac conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=johndoe-sunpac components=sunpac conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=janedoe-sunpac components=sunpac conf=conf/MoquiDevConfMySQL.xml
java -XX:+UseG1GC -jar moqui.war load types=demo-sunpac components=sunpac conf=conf/MoquiDevConfMySQL.xml
gradle runtime:component:sunpac:test -Pconf=conf/MoquiDevConfMySQL.xml
