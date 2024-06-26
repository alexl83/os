function pre_customize_image__251_install_custom_packages(){

	pkgs=(moreutils byobu git dkms gpsd zsh-autosuggestions macchanger avahi-daemon vnstat gpsd-tools libnss-mdns pwgen zerotier-one rfkill bluetooth bluez bluez-tools libpam-google-authenticator mtd-utils dnsmasq-base command-not-found)
	rem_pkgs=(ifupdown keyboard-configuration exim4-daemon-light haveged armbian-plymouth-theme armbian-zsh unattended-upgrades)
	rtc_board=(orangepi5-plus* nanopi-r5c)
	ir_board=(orangepi5-plus* orangepizero3 orangepizero2w)
	for rtc_match in "${rtc_board[@]}"; do
		if [ "${BOARD}" == "${rtc_match}" ]; then
			rem_pkgs+=(fake-hwclock)
		fi
	done
	for ir_match in "${ir_board[@]}"; do
		if [ "${BOARD}" == "${ir_match}" ]; then
			pkgs+=(lirc)
		fi
	done
	display_alert "Updating package list" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_update

	display_alert "Installing ${#pkgs[@]} packages:" "${pkgs[*]}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_install "${pkgs[@]}"
	display_alert "Purging ${#rem_pkgs[@]} packages:" "${rem_pkgs[*]}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_remove --auto-remove "${rem_pkgs[@]}"

}
