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

			DisableTTYs
			SetupStealthNetworking
			CopyConfigFiles
			SetupGpsd
			EnableDisableServices
			InstallAngryOxide
			ArmbianUserOverlayInstall
			UpdateArmbianEnvTxt
			;;

	esac

} # Main

ArmbianUserOverlayInstall()
{
	echo "Installing user overlays"
        if [ -d "/tmp/overlay/${BOARD}" ]; then
        for file in /tmp/overlay/${BOARD}/*.dts; do echo "installing $(basename ${file}) overlay"; armbian-add-overlay ${file}; done
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

EnableDisableServices()
{
	echo "Enabling/disabling additional/custom services"
#	systemctl enable gpsd.service
#	systemctl enable avahi-daemon
	systemctl disable zerotier-one.service
	if [ -f /etc/systemd/system/multi-user.target.wants/unattended-upgrades.service ]; then
	systemctl disable unattended-upgrades
	fi
	cp /tmp/overlay/common/rfcomm.service /etc/systemd/system
	systemctl enable rfcomm.service
}

CopyConfigFiles()
{
	echo "Blacklisting video and display output-related modules"
	cp /tmp/overlay/common/blacklist-videoout.conf /etc/modprobe.d
	if [ -f /etc/avahi/avahi-daemon.conf ]; then
	sed -i 's/^\#allow-interfaces.*/allow-interfaces\=eth0,sta0,nzt7nnkpung/g' /etc/avahi/avahi-daemon.conf
	fi
	cp /tmp/overlay/common/zshrc_skel /etc/skel/.zshrc
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

InstallAngryOxide()
 {
	echo "Downloading and installing angrixide latest build from gh:Ragnt/AngryOxide"
	mkdir /tmpinst
	cd /tmpinst
	wget https://github.com/Ragnt/AngryOxide/releases/latest/download/angryoxide-linux-aarch64-musl.tar.gz
	tar xfz angryoxide-linux-aarch64-musl.tar.gz
	chmod +x ./install
	./install install
	cd /
	rm -rf /tmpinst
	echo "Done installing AngryOxide"
}

UpdateArmbianEnvTxt()
{
	echo "Disabling verbosity, bootlogo, and console output in u-boot"
	if [ -f /boot/armbianEnv.txt ]; then
	sed -i 's/^verbosity.*/verbosity\=0/g' /boot/armbianEnv.txt
	sed -i 's/^bootlogo.*/bootlogo\=false/g' /boot/armbianEnv.txt
	sed -i 's/^console.*/console\=none/g' /boot/armbianEnv.txt
	echo "Enabling IR and UART5 overlays by default"
	echo "overlays=ir uart5-ph" >> /boot/armbianEnv.txt
	#sed -i 's/^overlays\=.*/overlays\=ir uart5-ph/g' /boot/armbianEnv.txt
	echo "Disabling Predictable net interface naming"
	echo "extraargs=net.ifnames=0" >> /boot/armbianEnv.txt
	fi

}
Main "$@"

