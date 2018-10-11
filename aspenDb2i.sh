#! /usr/bin/env bash
gradle cleanAllButDb -Duser.dir=`pwd`
# CLRLIB MOQUI
gradle load -Pconf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
gradle runtime:component:aspen:test -Pconf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
gradle runtime:component:gebbers:test -Pconf=conf/MoquiDevConfDb2i.xml -Duser.dir=`pwd`
