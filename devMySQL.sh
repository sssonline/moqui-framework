#! /usr/bin/env bash
java -server -XX:-OmitStackTraceInFastThrow -Xmx8192m -jar moqui.war conf=conf/MoquiDevConfMySQL.xml
