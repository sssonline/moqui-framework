#! /usr/bin/env bash
gradle cleanAll
gradle load -Ptypes=seed,seed-initial,install
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon,seed-gebbersSalary,seed-initial-gebbersSalary,install-gebbersSalary components=gebbers,gebbersal
java -XX:+UseG1GC -jar moqui.war load types=johndoe-gebbersSalary components=gebbersal
java -XX:+UseG1GC -jar moqui.war load types=janedoe-gebbersSalary components=gebbersal
java -XX:+UseG1GC -jar moqui.war load types=demo-gebbersSalary components=gebbersal
gradle runtime:component:gebbersal:test # -Darg1=GebbersSalary
