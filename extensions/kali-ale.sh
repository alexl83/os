function extension_prepare_config__docker() {
	EXTRA_IMAGE_SUFFIXES+=("-kali_ale") # global array
	display_alert "Target image will have Kali repository preinstalled" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
}

function pre_customize_image__250_1_install_kali_repositories() {

	display_alert "Adding gpg-key for Kali repository" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged curl --max-time 60 -4 -fsSL "https://archive.kali.org/archive-key.asc" "|" gpg --dearmor -o "${SDCARD}"/usr/share/keyrings/kali.gpg

	# Add sources.list
	if [[ "${DISTRIBUTION}" == "Debian" ]]; then
		display_alert "Adding sources.list for Kali" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/kali.gpg] http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" "|" tee "${SDCARD}"/etc/apt/sources.list.d/kali.list
		display_alert "Pinning Kali package versions to apt for consistency" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged cat <<- 'end' > "${SDCARD}"/etc/apt/preferences.d/kali
			Package: *
			Pin: release o=Kali
			Pin-Priority: 50
		end


	else
		exit_with_error "Unsupported distribution: ${DISTRIBUTION}" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	fi

	display_alert "Updating package lists with Kali Linux repository" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_update

}

function pre_customize_image__252_manage_config_files() {

	apt_confd=(/etc/apt/apt.conf.d/02-armbian-periodic /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/50unattended-upgrades)

	display_alert "Creating Wi-Fi white/blacklist files" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	if [ -f "${EXTENSION_DIR}"/overlay/common/wifi-whitelist ]; then
		display_alert "Found custom Wi-Fi whitelist - installing" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/wifi-whitelist "${SDCARD}"/usr/local/etc/wifi-whitelist
		else
		run_host_command_logged touch "${SDCARD}"/usr/local/etc/wifi-whitelist
	fi
	if [ -f "${EXTENSION_DIR}"/overlay/common/wifi-targets ]; then
		display_alert "Found custom Wi-Fi target list - installing" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/wifi-targets "${SDCARD}"/usr/local/etc/wifi-targets
		else
		run_host_command_logged touch "${SDCARD}"/usr/local/etc/wifi-targets
	fi

	display_alert "Disabling HID input" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/blacklist-usbhid.conf "${SDCARD}"/etc/modprobe.d

	if [ -f "${EXTENSION_DIR}"/overlay/common/blacklist-videoout-"${BOARD}".conf ]; then
		display_alert "Disabling video/display output" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/blacklist-videoout-"${BOARD}".conf "${SDCARD}"/etc/modprobe.d
	fi

	if [ -f "${EXTENSION_DIR}"/overlay/common/blacklist-misc-"${BOARD}".conf ]; then
		display_alert "Disabling misc ${BOARD} debug features" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/blacklist-misc-"${BOARD}".conf "${SDCARD}"/etc/modprobe.d
	fi

	if [ -f "${EXTENSION_DIR}"/overlay/common/rc.local-"${BOARD}" ]; then
		display_alert "Customizing rc.local for ${BOARD}" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/rc.local-"${BOARD}" "${SDCARD}"/etc/rc.local
	fi

	if [ -f "${SDCARD}"/etc/avahi/avahi-daemon.conf ]; then
		ethif=eth0
		if [ "${BOARD}" == "nanopi-r5c" ]; then
			ethif=wan
		fi
		display_alert "Allowing Avahi mDNS on designated interfaces only" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged sed -i "s/^\#allow-interfaces.*/allow-interfaces\="${ethif}",sta0,zt7nnkpung/g" "${SDCARD}"/etc/avahi/avahi-daemon.conf
		[[ -f "${SDCARD}"/usr/share/doc/avahi-daemon/examples/sftp-ssh.service ]] && run_host_command_logged cp "${SDCARD}"/usr/share/doc/avahi-daemon/examples/sftp-ssh.service "${SDCARD}"/etc/avahi/services/
		[[ -f "${SDCARD}"/usr/share/doc/avahi-daemon/examples/ssh.service ]] && run_host_command_logged cp "${SDCARD}"/usr/share/doc/avahi-daemon/examples/ssh.service "${SDCARD}"/etc/avahi/services/
	fi

	if [ -e "${EXTENSION_DIR}"/overlay/common/armbian-leds-"${BOARD}"-"${BRANCH}".conf ]; then
		display_alert "Setting up board leds" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
				if [ "${BOARD}" == "orangepizero2w" ]; then
					run_host_command_logged echo "ledtrig-netdev" >> "${SDCARD}"/etc/modules
				fi
		run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/armbian-leds-"${BOARD}"-"${BRANCH}".conf "${SDCARD}"/etc/armbian-leds.conf
	fi

	for file in "${SDCARD}"/"${apt_confd[@]}"; do
		if [ -f "${SDCARD}"/"${file}" ]; then
			display_alert "Disabling apt auto-checks" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
			run_host_command_logged mv "${SDCARD}"/"${file}"{,.disabled}
		fi
	done

	if [ -d "${EXTENSION_DIR}"/overlay/common/nm_system-connections ]; then
		for file in "${EXTENSION_DIR}"/overlay/common/nm_system-connections/"${BOARD}"-*.nmconnection; do
			if [ -f "${file}" ]; then
				finalfile=$(basename "${file}" | sed "s/"${BOARD}"-//g")
				display_alert "Installing Network-Manager connection profile: "${finalfile}"" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
				run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/nm_system-connections/"${file}" "${SDCARD}"/etc/NetworkManager/system-connections
			fi
		done

		if [ -f "${EXTENSION_DIR}"/overlay/common/nm_system-connections/BT-NAP.nmconnection ]; then
			display_alert "Installing Network-Manager BT-NAP connection profile" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
			run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/nm_system-connections/BT-NAP.nmconnection "${SDCARD}"/etc/NetworkManager/system-connections
		fi
	fi

	display_alert "Installing .zshrc skel" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/zshrc_skel "${SDCARD}"/etc/skel/.zshrc
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/zshrc_skel "${SDCARD}"/root/.zshrc

	display_alert "Cleaning build-time DNS from /etc/systemd/resolved.conf" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged sed -i 's/^DNS\=.*/#DNS\=/g' "${SDCARD}"/etc/systemd/resolved.conf

	display_alert "Applying sudo tweaks" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/sudoers.d/* "${SDCARD}"/etc/sudoers.d

	display_alert "Setting upstream wireless-regdb" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	chroot_sdcard update-alternatives --set regulatory.db /lib/firmware/regulatory.db-upstream

	display_alert "Installing 88x2bu and 8821au update script" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/update_rtl_improved.sh "${SDCARD}"/usr/local/bin
	run_host_command_logged chmod +x "${SDCARD}"/usr/local/bin/update_rtl_improved.sh

	display_alert "Disabling pam_systemd" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	chroot_sdcard pam-auth-update --disable systemd
}

function pre_customize_image__254_enable_disable_services() {
	services=(zerotier-one wpa_supplicant unattended-upgrades haveged console-setup networking)
	for service in "${services[@]}"; do
		if [[ $(chroot_sdcard systemctl list-unit-files --type service "|" grep -F "${service}") ]] && [[ $(chroot_sdcard systemctl is-enabled "${service}") ]]; then
			display_alert "disabling ${service}" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
			disable_systemd_service_sdcard "${service}"
		else display_alert "${service} service not found" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		fi
	done
	display_alert "installing rfcomm service for bluetooth GPS" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/rfcomm.service "${SDCARD}"/etc/systemd/system
	if [ -f "${EXTENSION_DIR}"/overlay/common/rfcomm.default_custom ]; then
		display_alert "Found custom rfcomm settings file: enabling service" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/rfcomm.default_custom "${SDCARD}"/etc/default/rfcomm
		chroot_sdcard systemctl --no-reload enable rfcomm.service
		else 
		run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/rfcomm.default "${SDCARD}"/etc/default/rfcomm
	fi
}

function pre_customize_image__255_update_armbian_env() {

	if [ -f "${SDCARD}"/boot/armbianEnv.txt ]; then
		display_alert "Disabling verbosity, bootlogo, and console output in u-boot" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged sed -i 's/^verbosity.*/verbosity\=0/g' "${SDCARD}"/boot/armbianEnv.txt
		run_host_command_logged sed -i 's/^bootlogo.*/bootlogo\=false/g' "${SDCARD}"/boot/armbianEnv.txt
		run_host_command_logged sed -i 's/^console.*/console\=none/g' "${SDCARD}"/boot/armbianEnv.txt

		if [ "${BOARD}" == "orangepizero3" ]; then
			display_alert "Enabling IR and UART5 overlays by default" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
			run_host_command_logged echo "overlays=ir uart5-ph" >> "${SDCARD}"/boot/armbianEnv.txt
		fi

		display_alert "Disabling Predictable net interface naming and kernel/splash verbosity" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged echo "extraargs=net.ifnames=0 quiet vt.global_cursor_default=0 nosplash" >> "${SDCARD}"/boot/armbianEnv.txt
	fi

}

function pre_customize_image__256_setup_stealth_networking()
{
	display_alert "Setting up udev-based mac randomization and automatic monitor interfaces creations" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	if [ "${BOARD}" != "nanopi-r5c" ]; then
		run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/udev-v7/70-persistent-net.rules "${SDCARD}"/etc/udev/rules.d
	else
		run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/udev-v7/70-persistent-net.rules "${SDCARD}"/etc/udev/rules.d/71-persistent-net.rules
	fi

	if [ ! -d "${SDCARD}"/usr/local/sbin ]; then
		run_host_command_logged mkdir -p "${SDCARD}"/usr/local/sbin
	fi
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/udev-v7/helpers/changemac.sh "${SDCARD}"/usr/local/sbin
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/udev-v7/helpers/createmon.sh "${SDCARD}"/usr/local/sbin
	run_host_command_logged chmod +x "${SDCARD}"/usr/local/sbin/createmon.sh
	run_host_command_logged chmod +x "${SDCARD}"/usr/local/sbin/changemac.sh

}

function pre_customize_image__257_install_angryoxide()
 {
	display_alert "Downloading and installing latest AngryOxide build from gh:Ragnt/AngryOxide" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged mkdir "${SDCARD}"/tmpinst
	chroot_sdcard cd /tmpinst
	chroot_sdcard wget -q https://github.com/Ragnt/AngryOxide/releases/latest/download/angryoxide-linux-aarch64-musl.tar.gz
	chroot_sdcard tar xfz angryoxide-linux-aarch64-musl.tar.gz
	chroot_sdcard chmod +x ./install
	chroot_sdcard ./install install
	chroot_sdcard cd /
	run_host_command_logged rm -rf "${SDCARD}"/tmpinst
	display_alert "Done installing AngryOxide" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
}

function pre_customize_image__258_1_install_dnsleaktest()
{
	display_alert "Installing dnsleaktest from gh:macvk/dnsleaktest" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	chroot_sdcard curl -s https://raw.githubusercontent.com/macvk/dnsleaktest/master/dnsleaktest.sh -o /usr/local/bin/dnsleaktest
	chroot_sdcard chmod +x /usr/local/bin/dnsleaktest

}

function pre_customize_image__259_disablettys()
{
	display_alert "Disabling serial consoles" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	for ((c=0; c<=9; c++)); do
		chroot_sdcard systemctl mask serial-getty@ttyS"${c}".service
	done
	if [ "${BRANCH}" == "vendor" ] || [ "${BRANCH}" == "legacy" ]; then
		chroot_sdcard systemctl mask serial-getty@ttyFIQ0.service
	fi
		display_alert "Disabling virtual consoles" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		chroot_sdcard systemctl mask getty@tty1
		chroot_sdcard systemctl mask console-setup
	if [ ! -d "${SDCARD}"/etc/systemd/logind.conf.d/ ]; then
		run_host_command_logged mkdir "${SDCARD}"/etc/systemd/logind.conf.d/
	fi
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/logind_00-disable-vtty.conf "${SDCARD}"/etc/systemd/logind.conf.d/disable-vtty.conf
	if [ ! -d "${SDCARD}"/etc/systemd/resolved.conf.d/ ]; then
		run_host_command_logged mkdir "${SDCARD}"/etc/systemd/resolved.conf.d/
	fi
	display_alert "Setting system-wide DNS over TLS and systemd-resolved tweaks" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/resolved*.conf "${SDCARD}"/etc/systemd/resolved.conf.d/


}

function pre_customize_image__260_add_firmware()
{
	display_alert "Installing additional firmware(s): e.g. MT7922" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged cp -r "${EXTENSION_DIR}"/overlay/firmware/* "${SDCARD}"/lib/firmware/
	run_host_command_logged cp -r "${EXTENSION_DIR}"/overlay/firmware/* "${SDCARD}"/usr/lib/firmware
}

function pre_customize_image__261_install_user_overlays()
{
	if [ -d "${EXTENSION_DIR}"/overlay/"${BOARD}" ]; then
		for file in "${EXTENSION_DIR}"/overlay/"${BOARD}"/*.dts; do
		if [ -f "${file}" ]; then
			run_host_command_logged mkdir "${SDCARD}"/tmpinst
			display_alert "Installing user overlays" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
			tgtfile=$(basename "${file}")
			display_alert "installing ${tgtfile} overlay" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
			run_host_command_logged cp "${file}" "${SDCARD}"/tmpinst
			chroot_sdcard armbian-add-overlay /tmpinst/"${tgtfile}"
			run_host_command_logged rm -rf "${SDCARD}"/tmpinst
		fi
		done
	fi

}

function pre_customize_image__262_setup_gpsd()
{
	case "${BOARD}" in

	orangepizero3)
	display_alert "Setting up GPSD" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged sed -i 's/^DEVICES\=.*/DEVICES\="\/dev\/ttyS0"/g' "${SDCARD}"/etc/default/gpsd
	;;

	orangepizero02w)
	display_alert "Setting up GPSD" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged sed -i 's/^DEVICES\=.*/DEVICES\="\/dev\/ttyS5"/g' "${SDCARD}"/etc/default/gpsd
	;;

	orangepi5-plus|nanopi-r5c)
	display_alert "Setting up GPSD" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged sed -i 's/^DEVICES\=.*/DEVICES\="\/dev\/rfcomm0"/g' "${SDCARD}"/etc/default/gpsd
	run_host_command_logged sed -i 's/^GPSD_OPTIONS\=\"\"/GPSD_OPTIONS\=\"-b\"/g' "${SDCARD}"/etc/default/gpsd
	;;

	esac

}
