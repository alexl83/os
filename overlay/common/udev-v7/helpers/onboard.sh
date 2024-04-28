#!/usr/bin/env bash
set -x

#helper script for onboard brcm wireless network setup

eval cmdline='$(cat /proc/cmdline)'
if [[ $cmdline =~ 'brcm_mode' ]]; then
 eval brcm_mode=$(cat /proc/cmdline | grep -E -o 'brcm_mode=[a-z]+' | cut -d "=" -f2)
else
 eval brcm_mode=""
fi

eval phy='$(cat /sys/class/net/$1/phy80211/name)'

case $brcm_mode in

ap)
 ifname=ap
 ifindex=$2
 /usr/bin/ifdata -e $ifname$ifindex 
 if [ $? -eq 0 ]
 then
  ifindex=$((ifindex+1))
 fi
 /sbin/iw phy $phy interface add $ifname$ifindex type __ap
 /bin/ip link set $ifname$ifindex address e4:5f:01:58:17:1f
 ;;

mon)
 ifname=mon
 ifindex=$2
 /usr/bin/ifdata -e $ifname$ifindex 
 if [ $? -eq 0 ]
 then
  ifindex=$((ifindex+1))
 fi
 /sbin/iw phy $phy interface add $ifname$ifindex type monitor
 ;;

*)
 exit 0
 ;;

esac
