function extension_prepare_config__docker() {
	EXTRA_IMAGE_SUFFIXES+=("-kali") # global array
	display_alert "Target image will have Kali repository preinstalled and Kali packages prioritized" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
}

#original extension_method "pre_install_kernel_deb"
#working  extension_method pre t64 breakage "pre_custoize_image"
#working  extension_methos post commit #6358 "post_install_kernel_debs"

function pre_customize_image__1_install_kali_packages(){
	pkgs="net-tools moreutils byobu git dkms gpsd zsh-autosuggestions macchanger avahi-daemon vnstat xauth gpsd-tools libnss-mdns zerotier-one wireless-regdb"

	display_alert "Adding gpg-key for Kali repository" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged curl --max-time 60 -4 -fsSL "https://archive.kali.org/archive-key.asc" "|" gpg --dearmor -o "${SDCARD}"/usr/share/keyrings/kali.gpg
	display_alert "Adding gpg-key for Zerotier repository" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged curl --max-time 60 -4 -fsSL "http://download.zerotier.com/contact%40zerotier.com.gpg" "|" gpg --dearmor -o "${SDCARD}"/usr/share/keyrings/zerotier-debian-package-key.gpg

	# Add sources.list
	if [[ "${DISTRIBUTION}" == "Debian" ]]; then
		display_alert "Adding sources.list for Kali." "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/kali.gpg] http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" "|" tee "${SDCARD}"/etc/apt/sources.list.d/kali.list
		display_alert "Pinning Kali package versions to apt for consistency." "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged cat <<- 'end' > "${SDCARD}"/etc/apt/preferences.d/kali
			Package: *
			Pin: release o=Kali
			Pin-Priority: 50
		end

		display_alert "Adding sources.list for Zerotier." "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/zerotier-debian-package-key.gpg] http://download.zerotier.com/debian/bookworm bookworm main" "|" tee "${SDCARD}"/etc/apt/sources.list.d/zerotier.list

	else
		exit_with_error "Unsupported distribution: ${DISTRIBUTION}"
	fi

	display_alert "Updating package lists with Kali Linux & Zerotier repositories" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_update

	display_alert "Adding packages: ${pkgs}" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_install ${pkgs}

}

#Do we need it?
#function pre_customize_image__2_fix_broken_packages() {

#	display_alert "Fixing broken packages" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
#	do_with_retries 3 chroot_sdcard_apt_get -o Dpkg::Options::='--force-confnew' -yy --allow-downgrades full-upgrade
#        do_with_retries 3 chroot_sdcard_apt_get --fix-missing update
#	do_with_retries 3 chroot_sdcard_apt_get  -f install
#	do_with_retries 3 chroot_sdcard_apt_get_update

#}
