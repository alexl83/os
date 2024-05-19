#!/usr/bin/env bash
set -euo pipefail
#set -x

# Logging setup
LOG_FILE="/var/log/driver_update.log"

log() {
    echo "$(date +"%Y-%m-%d %T") - $*" | sudo tee -a "$LOG_FILE"
}

# Input validation and sanitization
validate_paths() {
    for path in "$@"; do
        if [ ! -d "$path" ]; then
            log "Error: $path does not exist or is not a directory."
            exit 1
        fi
    done
}

# Dry run mode
dry_run=false
if [[ "${1:-}" == "--dry-run" ]]; then
    dry_run=true
    log "Dry run mode activated."
    shift
fi

# Validate and sanitize driver paths
validate_paths "${HOME}/8821au-20210708" "${HOME}/88x2bu-20210702"

# Set variables
drivers=("8821au-20210708" "${HOME}/88x2bu-20210702")
modprobe_path="/etc/modprobe.d"
rtl8821au_opts="options 8821au rtw_drv_log_level=0 rtw_led_ctrl=0 rtw_dfs_region_domain=3"
rtl88x2bu_opts="options 88x2bu rtw_drv_log_level=0 rtw_led_ctrl=0 rtw_vht_enable=1 rtw_switch_usb_mode=0 rtw_dfs_region_domain=3"
declare -A module_opts
module_opts["8821au"]="$rtl8821au_opts"
module_opts["88x2bu"]="$rtl88x2bu_opts"

# Function to fetch updates
fetch_updates() {
    cd "$1"
    git fetch origin || { log "Error: Failed to fetch updates for $module."; return 1; }
}

# Function to check if update is available
check_for_update() {
    if [ "$(git rev-parse HEAD)" = "$(git rev-parse "@{u}")" ]; then
        log "$module is up-to-date!"
        return 1
    else
        log "$module needs updating"
        return 0
    fi
}

# Function to update the driver
update_driver() {
 
   log "Pulling latest $module sources"
    if ! "$dry_run"; then
        git pull || { log "Error: Failed to pull latest suorces from git."; return 1; }
    fi
    log "Uninstalling old $module release"
    if ! "$dry_run"; then
        sudo ./remove-driver.sh NoPrompt || { log "Error: Failed to uninstall old $module release."; return 1; }
    fi

    log "Compiling and installing current $module release"
    if ! "$dry_run"; then
        sudo ./install-driver.sh NoPrompt || { log "Error: Failed to install current $module release."; return 1; }
    fi

    log "Updating $module modprobe options"
    if ! "$dry_run"; then
#      sudo  sed -e "s/^(options).*/${module_opts[$module]}/1" "${modprobe_path}/${module}.conf" || { log "Error: Failed to update modprobe configuration for $module."; return 1; }
      sed -r "s/^(options).*/${module_opts[$module]}/1" "${modprobe_path}/${module}.conf" | sudo tee "${modprobe_path}/${module}.conf" > /dev/null ||  { log "Error: Failed to update modprobe configuration for $module."; return 1; }
    fi

    log "$module updated!"
}

# Main loop to iterate over drivers
for driver in "${drivers[@]}"
    do
    module=$(basename "$driver" | cut -d - -f1)

    # Fetch updates
    fetch_updates "$driver" || continue

    # Check for updates
    if check_for_update; then
        update_driver || continue
    fi
done

echo "You should reboot your system now!"
#exit 0
