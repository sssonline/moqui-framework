#! /usr/bin/env bash
gradle cleanAll
gradle load -Ptypes=seed,seed-initial,install,demo
gradle runtime:component:aspen:test
#gradle runtime:component:gebbers:test
