#! /usr/bin/env bash
gradle cleanAllButDb
./cleanMySQL.sh
gradle load -Pconf=conf/MoquiDevConfMySQL.xml
gradle runtime:component:aspen:test -Pconf=conf/MoquiDevConfMySQL.xml
gradle runtime:component:gebbers:test -Pconf=conf/MoquiDevConfMySQL.xml
