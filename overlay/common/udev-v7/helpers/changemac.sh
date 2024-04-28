#!/usr/bin/env bash
set -x

case $1 in

 *mon*)
  if  [[ -e $(ls /sys/class/net/$1/device/net/* -d -1 | grep -v $1$) ]]
   then
    eval path=$(ls /sys/class/net/$1/device/net/* -d -1 | grep -v $1$)
    eval dev=$(basename $path)
    eval mac=$(cat $path/address)
    ip link set $1 down
    /usr/bin/macchanger $1 --mac $mac >/dev/null 2>&1
#    ip link set $1 up
   else
    ip link set $1 down
    /usr/bin/macchanger -a $1 >/dev/null 2>&1
#    ip link set $1 up
  fi
 ;;

 *)
  ip link set $1 down
  /usr/bin/macchanger -a $1 >/dev/null 2>&1
#  ip link set $1 up
 ;;

 esac
exit
