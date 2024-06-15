function pre_customize_image__250_3_install_syncthing_repositories() {

	display_alert "Adding gpg-key for Syncthing repository" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged curl --max-time 60 -4 -fsSL "https://syncthing.net/release-key.gpg" -o "${SDCARD}"/usr/share/keyrings/syncthing-archive-keyring.gpg

	# Add sources.list
	if [[ "${DISTRIBUTION}" == "Debian" ]]; then
		display_alert "Adding sources.list for Syncthing" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged echo "deb [arch="${ARCH}" signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" "|" tee "${SDCARD}"/etc/apt/sources.list.d/syncthing.list
		display_alert "Pinning Syncthing package versions to apt for consistency" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged cat <<- 'end' > "${SDCARD}"/etc/apt/preferences.d/syncthing
			Package: *
			Pin: release apt.syncthing.net
			Pin-Priority: 990
		end


	else
		exit_with_error "Unsupported distribution: ${DISTRIBUTION}" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	fi

	display_alert "Updating package lists with Syncthing Linux repository" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_update

}