function pre_customize_image__250_2_install_zerotier_packages(){

	display_alert "Adding gpg-key for Zerotier repository" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged curl --max-time 60 -4 -fsSL "http://download.zerotier.com/contact%40zerotier.com.gpg" "|" gpg --dearmor -o "${SDCARD}"/usr/share/keyrings/zerotier-debian-package-key.gpg
	# Add sources.list
	if [[ "${DISTRIBUTION}" == "Debian" ]]; then

		display_alert "Adding sources.list for Zerotier" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/zerotier-debian-package-key.gpg] http://download.zerotier.com/debian/bookworm bookworm main" "|" tee "${SDCARD}"/etc/apt/sources.list.d/zerotier.list

	else
		exit_with_error "Unsupported distribution: ${DISTRIBUTION}" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	fi

	display_alert "Updating package lists with Zerotier repository" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_update


}
