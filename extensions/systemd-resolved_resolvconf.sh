function pre_prepare_partitions__set_systemd-resolved(){
        display_alert "Cleaning deboostrapped resolv.conf" "${BOARD}:${RELEASE}-${BRANCH} :: ${EXTENSION}" "info"
        run_host_command_logged rm -vf "${SDCARD}"/etc/resolv.conf
}
