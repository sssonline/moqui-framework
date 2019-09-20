#! /usr/bin/env bash
gradle cleanAll
gradle load -Pcomponents=example,tools,webroot,HiveMind,SimpleScreens,mantle-edi,mantle-udm,mantle-usl,moqui-elasticsearch,moqui-fop
