#! /usr/bin/env bash
#java -server -XX:-OmitStackTraceInFastThrow -Xmx8192m -jar moqui.war conf=conf/MoquiProductionConfDb2i.xml
java -XX:-OmitStackTraceInFastThrow -Xmx8192m -jar moqui.war conf=conf/MoquiProductionConfDb2i.xml
