#!/usr/bin/env bash

# Enable strict mode:
set -euo pipefail

# Function to create or rename a monitor interface for a given wlan interface
create_or_rename_mon() {
  local wlan_interface=$1
  local phy_num=$(iw dev "$wlan_interface" info | awk '/wiphy/ {print $2}')
  local mon_interface="mon${phy_num}"
  local driver

  # Get the driver for the wlan interface using udevadm
  driver=$(udevadm info --query=property --path=/sys/class/net/"$wlan_interface" | awk -F'=' '/DRIVER/ {print $2}')

  # Check if a monitor interface for this phy already exists
  if [[ -n $(iw dev | awk '/Interface/ {print $2}' | grep "^mon${phy_num}$") ]]; then
    echo "Monitor interface mon${phy_num} already exists for phy${phy_num}."
    return 0
  fi

  # Check if the driver is one of the unsupported ones for VIF mode
  if [[ $driver =~ rtl88[[:alnum:]]*au|rtl88[[:alnum:]]*bu|rtl88XXbu ]]; then
    # The driver does not support VIF mode; rename the interface instead
    ip link set "$wlan_interface" down
    ip link set "$wlan_interface" name "$mon_interface"
    iw "$mon_interface" set monitor none
    echo "Interface $wlan_interface renamed to $mon_interface and set to monitor mode."
  else
    # The driver supports VIF mode; create the monitor interface
    if ! iw "$wlan_interface" interface add "$mon_interface" type monitor; then
      echo "Failed to create monitor interface $mon_interface for $wlan_interface."
      return 1
    fi
    echo "Monitor interface $mon_interface created for $wlan_interface."
  fi
}

# Main execution block
for wlan_interface in $(iw dev | awk '/Interface/ {print $2}'); do
  if [[ $wlan_interface == wlan* ]]; then
    create_or_rename_mon "$wlan_interface"
  fi
done