function extension_prepare_config__docker() {
	EXTRA_IMAGE_SUFFIXES+=("-kali") # global array
	display_alert "Target image will have Kali repository preinstalled and Kali packages prioritized" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
}

#original extension_method "pre_install_kernel_deb"
#working  extension_method pre t64 breakage "pre_customize_image"
#working  extension_method post commit #6358 "post_install_kernel_debs"

function pre_customize_image__001_install_kali_repositories() {

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

function pre_customize_image__002_manage_config_files() {

	apt_confd=(/etc/apt/apt.conf.d/02-armbian-periodic /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/50unattended-upgrades)

	display_alert "Creating Wi-Fi white/blacklist files" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged touch "${SDCARD}"/usr/local/etc/wifi-whitelist
	run_host_command_logged touch "${SDCARD}"/usr/local/etc/wifi-targets

	display_alert "Disabling local keyboard/mouse input" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/blacklist-usbhid.conf "${SDCARD}"/etc/modprobe.d

	if [ -f "${EXTENSION_DIR}"/overlay/common/blacklist-videoout-"${BOARD}".conf ]; then
	display_alert "Disabling video/display output" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	cp "${EXTENSION_DIR}"/overlay/common/blacklist-videoout-"${BOARD}".conf "${SDCARD}"/etc/modprobe.d
	fi

	if [ -f "${SDCARD}"/etc/avahi/avahi-daemon.conf ]; then
	display_alert "Allowing Avahi mDNS on designated interfaces only" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged sed -i 's/^\#allow-interfaces.*/allow-interfaces\=eth0,sta0,zt7nnkpung/g' "${SDCARD}"/etc/avahi/avahi-daemon.conf
	fi

	if [ -f "${EXTENSION_DIR}"/overlay/common/armbian-leds-"${BOARD}".conf ]; then
	display_alert "Setting up board leds" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/armbian-leds-"${BOARD}".conf "${SDCARD}"/etc/armbian-leds.conf
	fi

	for file in "${SDCARD}"/"${apt_confd[@]}"; do
		if [ -f "${SDCARD}"/"${file}" ]; then
		display_alert "Disabling apt auto-checks" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged mv "${SDCARD}"/"${file}"{,.disabled}
		fi
	done

	display_alert "Cleaning build-time DNS from /etc/systemd/resolved.conf" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged sed -i 's/^DNS\=.*/#DNS\=/g' "${SDCARD}"/etc/systemd/resolved.conf

	display_alert "Applying sudo tweaks" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/sudoers.d/* "${SDCARD}"/etc/sudoers.d

}

function pre_customize_image__004_enable_disable_services() {
	services=(zerotier-one wpa_supplicant networking unattended-upgrades haveged)
	for service in "${services[@]}"; do
		if [ $(chroot_sdcard systemctl is-enabled "${service}") ]; then
		display_alert "disabling "${service}"" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}"
		chroot_sdcard systemctl disable "${service}"
		fi
	done
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/rfcomm.service "${SDCARD}"/etc/systemd/system
	run_host_command_logged cp "${EXTENSION_DIR}"/overlay/common/rfcomm.default "${SDCARD}"/etc/default/rfcomm
}

function pre_customize_image_005_update_armbian_env() {

	if [ -f "${SDCARD}"/boot/armbianEnv.txt ]; then
	display_alert "Disabling verbosity, bootlogo, and console output in u-boot" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}"
	run_host_command_logged sed -i 's/^verbosity.*/verbosity\=0/g' "${SDCARD}"/boot/armbianEnv.txt
	run_host_command_logged sed -i 's/^bootlogo.*/bootlogo\=false/g' "${SDCARD}"/boot/armbianEnv.txt
	run_host_command_logged sed -i 's/^console.*/console\=none/g' "${SDCARD}"/boot/armbianEnv.txt

		if [ "${BOARD}" == "orangepizero3" ]; then
		display_alert "Enabling IR and UART5 overlays by default"
		run_host_command_logged echo "overlays=ir uart5-ph" >> "${SDCARD}"/boot/armbianEnv.txt
		fi

	display_alert "Disabling Predictable net interface naming and kernel/splash verbosity"
	run_host_command_logged echo "extraargs=net.ifnames=0 quiet vt.global_cursor_default=0 nosplash" >> "${SDCARD}"/boot/armbianEnv.txt
	fi

}
