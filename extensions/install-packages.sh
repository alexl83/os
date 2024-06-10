function pre_customize_image__251_install_custom_packages(){

	pkgs=(net-tools moreutils byobu git dkms gpsd zsh-autosuggestions macchanger avahi-daemon vnstat xauth gpsd-tools libnss-mdns pwgen zerotier-one rfkill bluetooth bluez bluez-tools lirc libpam-google-authenticator mtd-utils)
	rem_pkgs=(ifupdown keyboard-configuration exim4-daemon-light)
	if [ "${BOARD}" == "orangepi5-plus" ]; then
		rem_pkgs+=(fake-hwclock)
	fi	
	display_alert "Updating package list" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_update

	display_alert "Installing ${#pkgs[@]} packages:" "${pkgs[*]}" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_install "${pkgs[@]}"
	display_alert "Purging ${#rem_pkgs[@]} packages:" "${rem_pkgs[*]}" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_remove --auto-remove "${rem_pkgs[@]}"

}
