#!/usr/bin/env bash

case $1 in;

*mon*) 

*) /usr/bin/macchanger -a -b $1 >/dev/null 2>&1
