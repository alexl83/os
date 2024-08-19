function pre_customize_image__251_install_custom_packages() {

	pkgs=(byobu git dkms gpsd zsh-autosuggestions avahi-daemon vnstat gpsd-tools libnss-mdns pwgen arping zerotier-one rfkill bluetooth bluez bluez-tools libpam-google-authenticator dnsmasq-base)
	rem_pkgs=(ifupdown keyboard-configuration exim4-daemon-light haveged unattended-upgrades)
	rtc_board=(orangepi5-plus nanopi-r5c rock-5b)
	ir_board=(orangepi5-plus orangepizero3 orangepizero2w)
	spi_nor_board=(orangepizero2w orangepizero3 orangepi5-plus rock-5b)
		if [[ " ${rtc_board[*]} " =~ " ${BOARD%-*} " ]] || [[ " ${rtc_board[*]} " =~ " ${BOARD} " ]]; then
			rem_pkgs+=(fake-hwclock)
		fi
		
		if [[ " ${ir_board[*]} " =~ " ${BOARD%-*} " ]] || [[ " ${ir_board[*]} " =~ " ${BOARD} " ]]; then
			pkgs+=(lirc)
		fi
		
		if [[ " ${spi_nor_board[*]} " =~ " ${BOARD%-*} " ]] || [[ " ${spi_nor_board[*]} " =~ " ${BOARD} " ]]; then
			pkgs+=(mtd-utils)
		fi

	display_alert "Updating package list" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_update

	display_alert "Installing ${#pkgs[@]} packages:" "${pkgs[*]}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_install "${pkgs[*]}"
	display_alert "Purging ${#rem_pkgs[@]} packages:" "${rem_pkgs[*]}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_remove --auto-remove "${rem_pkgs[*]}"

}
