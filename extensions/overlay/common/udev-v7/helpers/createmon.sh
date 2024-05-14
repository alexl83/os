#!/usr/bin/env bash

set -x

if [[ -e /sys/class/net/$1 ]]
then
 ifname=mon
 ifindex=$2
 /usr/bin/ifdata -e $ifname$ifindex
 if [ $? -eq 0 ]
 then
  ifindex=$((ifindex+1))
 fi
fi
iface=$ifname$ifindex
 used_driver="$(udevadm info /sys/class/net/$1 | grep -e "ID_NET_DRIVER=" | cut -d"=" -f 2)"
   if [[ ${used_driver} != "rtl88"*"au" ]] && [[ ${used_driver} != "rtl88"*"bu" ]] && [[ ${used_driver} != "rtl88XXbu" ]]
   then
    iw dev $1 interface add $iface type monitor
#    ip link set $iface up
   else
     ip link set $1 down
     ip link set $1 name $iface
     iw dev $iface set type monitor
     iw dev $iface set monitor none
#     ip link set $iface up

   fi

