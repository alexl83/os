#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
	case $RELEASE in
		stretch)
			# your code here
			;;
		buster)
			# your code here
			;;
		bullseye)
			# your code here
			;;
		bionic)
			# your code here
			;;
		focal)
			# your code here
			;;

		bookworm|trixie|sid|jammy)
			SetupStealthNetworking
			DisableTTYs
			EnableServices
			ArmbianUserOverlayInstall
			CopyConfigFiles
			SetupGpsd
			UpdateArmbianEnvTxt
			;;

	esac

} # Main

#CustomizeForAle()
#{
#	apt-get install -yy net-tools moreutils armbian-zsh armbian-config kismet wifite airgeddon byobu git dkms gpsd git zsh zsh-autosuggestions

#}

ArmbianUserOverlayInstall()
{
	echo "Installing user overlays"
        if [ -d "/tmp/overlay/${BOARD}" -a -f "/tmp/overlay/${BOARD}/*.dts" ]; then
        for file in /tmp/overlay/${BOARD}/*.dts; do armbian-add-overlay ${file}; done
        fi

}


SetupStealthNetworking()
{
	echo "Setting up udev-based mac randomization and automatic monitor interfaces creations"
        cp /tmp/overlay/common/udev-v7/70-persistent-net.rules /etc/udev/rules.d
        if [ ! -d /usr/local/sbin ]; then
        mkdir -p /usr/local/sbin
        fi
        cp /tmp/overlay/common/udev-v7/helpers/changemac.sh /usr/local/sbin
        cp /tmp/overlay/common/udev-v7/helpers/createmon.sh /usr/local/sbin
        chmod +x /usr/local/sbin/createmon.sh
	chmod +x /usr/local/sbin/changemac.sh

}

DisableTTYs()
{
	echo "Disabling serial consoles"
        systemctl mask serial-getty@ttyS0.service
        systemctl mask serial-getty@ttyS1.service
        systemctl mask serial-getty@ttyS2.service
        systemctl mask serial-getty@ttyS5.service
	echo "Disabling virtual consoles"
	mkdir /etc/systemd/logind.conf.d/
	cp /tmp/overlay/common/logind_00-disable-vtty.conf /etc/systemd/logind.conf.d/

}

EnableServices()
{
	echo "Enabling additional/custom services"
#	systemctl enable gpsd.service
	cp /tmp/overlay/common/rfcomm.service /etc/systemd/system
	systemctl enable rfcomm.service
}

CopyConfigFiles()
{
	echo "Blacklisting video and display output-related modules"
	cp /tmp/overlay/common/blacklist-videoout.conf /etc/modprobe.d
#	cp /tmp/overlay/common/kismet.conf /etc

}

SetupGpsd()
{
	echo "Setting up GPSD"
	if [ ${BOARD} == "orangepizero3" ]; then
	sed -i 's/DEVICES=.*/DEVICES="\/dev\/ttyS0"/g' /etc/default/gpsd
	elif [ ${BOARD} == "orangepizero02w" ]; then
	sed -i 's/DEVICES=.*/DEVICES="\/dev\/ttyS5"/g' /etc/default/gpsd
	fi

}

UpdateArmbianEnvTxt()
{
	echo "Disabling verbosity, bootlogo, and console output in u-boot"
	if [ -f /boot/armbianEnv.txt ]; then
	sed -i 's/^verbosity.*/verbosity\=0/g' /boot/armbianEnv.txt
	sed -i 's/^bootlogo.*/bootlogo\=false/g' /boot/armbianEnv.txt
	sed -i 's/^console.*/console\=none/g' /boot/armbianEnv.txt
	echo "Disabling Predictable net interface naming"
	echo "extraargs=net.ifnames=0" >> /boot/armbianEnv.txt
	fi

}
Main "$@"

