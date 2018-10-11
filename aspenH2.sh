#! /usr/bin/env bash
gradle cleanAll
gradle load
gradle runtime:component:aspen:test
gradle runtime:component:gebbers:test
