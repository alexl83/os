function pre_install_distribution_specific__1_disable_cnf_apt_hook(){
        display_alert "Disabling command-not-found during build-time to speed up image creation" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
        run_host_command_logged mv "${SDCARD}"/etc/apt/apt.conf.d/50command-not-found "${SDCARD}"/etc/apt/apt.conf.d/50command-not-found.disabled
}


function post_post_debootstrap_tweaks__2_restore_cnf_apt_hook(){
        display_alert "Enabling command-not-found after build-time " "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
        run_host_command_logged mv "${SDCARD}"/etc/apt/apt.conf.d/50command-not-found.disabled "${SDCARD}"/etc/apt/apt.conf.d/50command-not-found

}
