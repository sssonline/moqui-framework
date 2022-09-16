#! /usr/bin/env bash
gradle cleanAll
gradle load -Ptypes=seed,seed-initial,install
java -XX:+UseG1GC -jar moqui.war load types=seed-gebbersCommon,seed-initial-gebbersCommon,install-gebbersCommon,seed-brewsterPayrollServices,seed-initial-brewsterPayrollServices,install-brewsterPayrollServices components=gebbers,gebbersb
java -XX:+UseG1GC -jar moqui.war load types=johndoe-brewsterPayrollServices components=gebbersb
java -XX:+UseG1GC -jar moqui.war load types=janedoe-brewsterPayrollServices components=gebbersb
java -XX:+UseG1GC -jar moqui.war load types=demo-brewsterPayrollServices components=gebbersb
gradle runtime:component:gebbersb:test # -Darg1=brewsterPayrollServices
