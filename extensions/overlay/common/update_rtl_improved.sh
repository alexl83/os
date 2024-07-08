#!/usr/bin/env bash
set -euo pipefail

# Logging setup
LOG_FILE="/var/log/driver_update.log"

log() {
    echo "$(date +"%Y-%m-%d %T") - $*" | sudo tee -a "$LOG_FILE"
}

# Source external file for options
source /etc/default/update_rtl_options

# Input validation and sanitization
validate_and_prepare_paths() {
    for path in "$@"; do
        if [ ! -d "$path" ]; then
            log "$path does not exist. Creating directory and cloning repository."
            git clone "https://github.com/morrownr/$(basename "$path").git" "$path" || {
                log "Error: Failed to clone repository for $(basename "$path")."
                exit 1
            }
        else
            log "$path exists. Checking for updates."
            cd "$path"
            git fetch origin || {
                log "Error: Failed to fetch updates for $(basename "$path")."
                exit 1
            }
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

# Set variables
drivers=("${HOME}/8821au-20210708" "${HOME}/88x2bu-20210702")
modprobe_path="/etc/modprobe.d"
declare -A module_opts
module_opts["8821au"]="$rtl8821au_opts"
module_opts["88x2bu"]="$rtl88x2bu_opts"

# Function to check if update is available
check_for_update() {
    if [ "$(git rev-parse HEAD)" = "$(git rev-parse "@{u}")" ]; then
        log "$1 is up-to-date!"
        return 1
    else
        log "$1 needs updating"
        return 0
    fi
}

# Function to update the driver
update_driver() {
    log "Pulling latest $1 sources"
    if ! $dry_run; then
        git pull || { log "Error: Failed to pull latest sources from git."; return 1; }
    fi
    log "Uninstalling old $1 release"
    if ! $dry_run; then
        sudo ./remove-driver.sh NoPrompt || { log "Error: Failed to uninstall old $1 release."; return 1; }
    fi

    log "Compiling and installing current $1 release"
    if ! $dry_run; then
        sudo ./install-driver.sh NoPrompt || { log "Error: Failed to install current $1 release."; return 1; }
    fi

    log "Updating $1 modprobe options"
    if ! $dry_run; then
        echo "${module_opts[$1]}" | sudo tee "${modprobe_path}/${1}.conf" > /dev/null || { log "Error: Failed to update modprobe configuration for $1."; return 1; }
    fi

    log "$1 updated!"
    return 0
}

# Validate and prepare driver paths
validate_and_prepare_paths "${drivers[@]}"

# Main loop to iterate over drivers
reboot_required=false
for driver in "${drivers[@]}"; do
    module=$(basename "$driver" | cut -d - -f1)

    # Change to driver directory
    cd "$driver"

    # Fetch updates
    git fetch origin || continue

    # Check for updates
    if check_for_update "$module"; then
        if update_driver "$module"; then
            reboot_required=true
        fi
    fi
done

if $reboot_required; then
    echo "At least one driver has been updated. You should reboot your system now!"
else
    echo "No driver updates were necessary. No reboot required."
fi