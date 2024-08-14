#!/usr/bin/env bash

# Enable strict mode:
set -euo pipefail

# Function to randomize the MAC address
randomize_mac() {
  local interface=$1

  # Bring down the interface to change the MAC address
  ip link set "$interface" down

  # Change the MAC address to a random one
  macchanger -r "$interface" > /dev/null

  # Bring up the interface with the new MAC address
#  ip link set "$interface" up
}

# Function to sync the MAC address of a mon interface with its parent wlan interface
sync_mac() {
  local mon_interface=$1
  local phy_num=$(iw dev "$mon_interface" info | awk '/wiphy/ {print $2}')
  local wlan_interface="wlan${phy_num}"

  # Get the current MAC address of the wlan interface
  local wlan_mac=$(ip link show "$wlan_interface" | awk '/ether/ {print $2}')

  # Apply the MAC address to the monitor interface
  ip link set "$mon_interface" down
  ip link set "$mon_interface" address "$wlan_mac"
#  ip link set "$mon_interface" up
}

# Main execution block
if [[ $1 == wlan* ]]; then
  randomize_mac "$1"
elif [[ $1 == mon* ]]; then
  sync_mac "$1"
else
  echo "Unsupported interface type for this script."
  exit 1
fi