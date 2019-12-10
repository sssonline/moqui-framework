#! /usr/bin/env bash
gradle cleanAll
gradle load -Ptypes=seed,seed-initial,install
java -XX:+UseG1GC -jar moqui.war load types=seed-sunpac,seed-initial-sunpac,install-sunpac components=sunpac
java -XX:+UseG1GC -jar moqui.war load types=johndoe-sunpac components=sunpac
java -XX:+UseG1GC -jar moqui.war load types=janedoe-sunpac components=sunpac
java -XX:+UseG1GC -jar moqui.war load types=demo-sunpac components=sunpac
gradle runtime:component:sunpac:test
