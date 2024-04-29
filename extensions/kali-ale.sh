function extension_prepare_config__docker() {
	EXTRA_IMAGE_SUFFIXES+=("-kali") # global array
	display_alert "Target image will have Kali repository preinstalled and Kali packages prioritized" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
}


function pre_customize_image__install_armbian_stuff(){
	pkgs="armbian-zsh armbian-config net-tools moreutils byobu git dkms gpsd zsh-autosuggestions macchanger avahi-daemon vnstat xauth x11-utils gpsd-tools wireless-regdb"
	display_alert "Temporarily enabling Armbian Repo" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged mv "${SDCARD}"/etc/apt/sources.list.d/armbian.list.disabled "${SDCARD}"/etc/apt/sources.list.d/armbian.list
        do_with_retries 3 chroot_sdcard_apt_get_update
	display_alert "Adding packages: ${pkgs}" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_install ${pkgs}
        display_alert "Disnabling Armbian Repo" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
        run_host_command_logged mv "${SDCARD}"/etc/apt/sources.list.d/armbian.list "${SDCARD}"/etc/apt/sources.list.d/armbian.list.disabled
	do_with_retries 3 chroot_sdcard_apt_get_update

} #<extension_method>__install_armbian_stuff()

function pre_customize_image__install_kali_packages(){
	packages="net-tools moreutils byobu git dkms gpsd git zsh zsh-autosuggestions macchanger avahi-daemon"
	display_alert "Adding gpg-key for Kali repository" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged curl --max-time 60 -4 -fsSL "https://archive.kali.org/archive-key.asc" "|" gpg --dearmor -o "${SDCARD}"/usr/share/keyrings/kali.gpg
	display_alert "Adding gpg-key for Zerotier repository" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged curl --max-time 60 -4 -fsSL "http://download.zerotier.com/contact%40zerotier.com.gpg" "|" gpg --dearmor -o "${SDCARD}"/usr/share/keyrings/zerotier-debian-package-key.gpg

	# Add sources.list
	if [[ "${DISTRIBUTION}" == "Debian" ]]; then
		display_alert "Adding sources.list for Kali." "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/kali.gpg] http://http.kali.org/kali kali-rolling main non-free contrib" "|" tee "${SDCARD}"/etc/apt/sources.list.d/kali.list
		display_alert "Pinning Kali package versions to apt for consistency." "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged cat <<- 'end' > "${SDCARD}"/etc/apt/preferences.d/kali
			Package: *
			Pin: release o=kali
			Pin-Priority: 1000
		end

		display_alert "Adding sources.list for Zerotier." "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
		run_host_command_logged echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/zerotier-debian-package-key.gpg] http://download.zerotier.com/debian/bookworm bookworm main" "|" tee "${SDCARD}"/etc/apt/sources.list.d/zerotier.list

	else
		exit_with_error "Unsupported distribution: ${DISTRIBUTION}"
	fi

	display_alert "Updating package lists with Kali Linux & Zerotier repositories" "${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_update

	# Optional preinstall top 10 tools
#	display_alert "Installing Top 10 Kali Linux tools" "${EXTENSION}" "info"
#	chroot_sdcard_apt_get_install kali-tools-top10
}

#function post_customize_image__kali_tools() {
#	display_alert "Adding Kali Linux profile package list show ${RELEASE}" "${EXTENSION}" "info"
#	run_host_command_logged mkdir -p "${SDCARD}"/etc/armbian/
#	run_host_command_logged cat <<- 'armbian-kali-motd' > "${SDCARD}"/etc/armbian/kali.sh
		#!/bin/bash
		#
		# Copyright (c) Authors: https://www.armbian.com/authors
		#
#		echo -e "\n\e[0;92mAdditional security oriented packages you can install:\x1B[0m (sudo apt install kali-tools-package_name)\n"
#		apt list 2>/dev/null | grep kali-tools | grep -v installed | cut -d"/" -f1 | pr -2 -t
#		echo ""
#	armbian-kali-motd
#	run_host_command_logged chmod +x "${SDCARD}"/etc/armbian/kali.sh
#	run_host_command_logged echo ". /etc/armbian/kali.sh" >> "${SDCARD}"/etc/skel/.bashrc
#	run_host_command_logged echo ". /etc/armbian/kali.sh" >> "${SDCARD}"/etc/skel/.zshrc
#	run_host_command_logged echo ". /etc/armbian/kali.sh" >> "${SDCARD}"/root/.bashrc
#}
