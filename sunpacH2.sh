#! /usr/bin/env bash
gradle cleanAll
gradle load -Ptypes=seed,seed-initial,install
java -XX:+UseG1GC -jar moqui.war load types=johndoe,demo components=sunpac
gradle runtime:component:sunpac:test
