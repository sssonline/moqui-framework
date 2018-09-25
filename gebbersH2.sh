#! /usr/bin/env bash
gradle cleanAll
gradle load -Ptypes=seed,seed-initial,install
java -jar moqui.war load types=demo components=webroot,gebbers
gradle runtime:component:gebbers:test
