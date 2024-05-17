function post_post_debootstrap_tweaks__250_set_systemd-resolved(){
	display_alert "Asking NetworkManager to not handle /etc/resolv.conf" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
	run_host_command_logged sed -i 's/^dns\=.*/dns\=none/g' "${SDCARD}"/etc/NetworkManager/NetworkManager.conf
	run_host_command_logged sed -i 's/rc-manager\=.*/rc-manager\=unmanaged/g' "${SDCARD}"/etc/NetworkManager/NetworkManager.conf
        display_alert "Cleaning deboostrapped resolv.conf - systemd-resolved to take over" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
        run_host_command_logged rm -f "${SDCARD}"/etc/resolv.conf
}
