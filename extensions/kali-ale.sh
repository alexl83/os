function extension_prepare_config__docker() {
	EXTRA_IMAGE_SUFFIXES+=("-kali") # global array
	display_alert "Target image will have Kali repository preinstalled and Kali packages prioritized" "${EXTENSION}" "info"
}


#function image_tweaks_post_customize__install_armbian_stuff(){
#	pkgs="armbian-zsh armbian-config"
#	display_alert "Adding packages: ${pkgs}" "${EXTENSION}" "info"
#        do_with_retries 3 chroot_sdcard_apt_get_update
#	do_with_retries 3 chroot_sdcard_apt_get_install --allow-downgrades ${pkgs}

#} #<extension_method>__install_armbian_stuff()

function pre_customize_image__install_kali_packages(){
	packages="net-tools moreutils byobu git dkms gpsd git zsh zsh-autosuggestions macchanger"
	display_alert "Adding gpg-key for Kali repository" "Debian :: ${EXTENSION}" "info"
	run_host_command_logged curl --max-time 60 -4 -fsSL "https://archive.kali.org/archive-key.asc" "|" gpg --dearmor -o "${SDCARD}"/usr/share/keyrings/kali.gpg

	# Add sources.list
	if [[ "${DISTRIBUTION}" == "Debian" ]]; then
		display_alert "Adding sources.list for Kali." "Debian :: ${EXTENSION}" "info"
		run_host_command_logged echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/kali.gpg] http://http.kali.org/kali kali-rolling main non-free contrib" "|" tee "${SDCARD}"/etc/apt/sources.list.d/kali.list
		display_alert "Pinning Kali package versions to apt for consistency." "Debian :: ${EXTENSION}" "info"
		run_host_command_logged cat <<- 'end' > "${SDCARD}"/etc/apt/preferences.d/kali
			Package: *
			Pin: release o=kali
			Pin-Priority: 1000
		end
	else
		exit_with_error "Unsupported distribution: ${DISTRIBUTION}"
	fi

	display_alert "Updating package lists with Kali Linux repos" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_update
	display_alert "Installing packages: ${packages}" "${EXTENSIONS}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_install --allow-downgrades ${packages}

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
