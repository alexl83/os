# Rockchip RK3588 octa core 4/8/16GB RAM SoC SPI NVMe 2x USB2 2x USB3 1x USB-C 2x 2.5GbE 3x HDMI
BOARD_NAME="Orange Pi 5 Plus"
BOARDFAMILY="rockchip-rk3588"
BOARD_MAINTAINER="efectn"
BOOTCONFIG="orangepi_5_plus_defconfig" # vendor name, not standard, see hook below, set BOOT_SOC below to compensate
BOOT_SOC="rk3588"
KERNEL_TARGET="legacy,vendor,current,edge"
KERNEL_TEST_TARGET="vendor,edge"
FULL_DESKTOP="yes"
BOOT_LOGO="desktop"
BOOT_FDT_FILE="rockchip/rk3588-orangepi-5-plus.dtb"
BOOT_SCENARIO="spl-blobs"
DDR_BLOB='rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.16.bin'
BL31_BLOB='rk35/rk3588_bl31_v1.45.elf'
BOOT_SUPPORT_SPI="yes"
BOOT_SPI_RKSPI_LOADER="yes"
IMAGE_PARTITION_TABLE="gpt"
declare -g UEFI_EDK2_BOARD_ID="orangepi-5plus" # This _only_ used for uefi-edk2-rk3588 extension

function post_family_tweaks__orangepi5plus_naming_audios() {
	display_alert "$BOARD" "Renaming orangepi5 audios" "info"

	mkdir -p $SDCARD/etc/udev/rules.d/
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmi0-sound", ENV{SOUND_DESCRIPTION}="HDMI0 Audio"' > $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmi1-sound", ENV{SOUND_DESCRIPTION}="HDMI1 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmiin-sound", ENV{SOUND_DESCRIPTION}="HDMI-In Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-dp0-sound", ENV{SOUND_DESCRIPTION}="DP0 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-es8388-sound", ENV{SOUND_DESCRIPTION}="ES8388 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules

	return 0
}

# Use vendor-provided U-Boot for 'legacy' kernel branch; let's avoid conditionals in family config.
function post_family_config_branch_legacy__orangepi5plus_use_vendor_uboot() {
	BOOTSOURCE='https://github.com/orangepi-xunlong/u-boot-orangepi.git'
	BOOTBRANCH='branch:v2017.09-rk3588'
	BOOTPATCHDIR="legacy/u-boot-orangepi5-rk3588"
}

# Use vendor-provided U-Boot for 'vendor' kernel branch; let's avoid conditionals in family config.
function post_family_config_branch_vendor__orangepi5plus_use_vendor_uboot() {
	BOOTSOURCE='https://github.com/orangepi-xunlong/u-boot-orangepi.git'
	BOOTBRANCH='branch:v2017.09-rk3588'
	BOOTPATCHDIR="legacy/u-boot-orangepi5-rk3588"
}

# Mainline U-Boot for edge kernel
function post_family_config_branch_edge__orangepi5plus_use_mainline_uboot() {
	display_alert "$BOARD" "Mainline U-Boot overrides for $BOARD - $BRANCH" "info"

	declare -g BOOTCONFIG="orangepi-5-plus-rk3588_defconfig"      # override the default for the board/family
	declare -g BOOTDELAY=1                                        # Wait for UART interrupt to enter UMS/RockUSB mode etc
	declare -g BOOTSOURCE="https://github.com/u-boot/u-boot.git"  # We ❤️ mainline U-Boot
	declare -g BOOTBRANCH="tag:v2024.07-rc4"
	declare -g BOOTPATCHDIR="v2024.07/board_${BOARD}"
	declare -g BOOTDIR="u-boot-${BOARD}"                          # do not share u-boot directory
	declare -g UBOOT_TARGET_MAP="BL31=${RKBIN_DIR}/${BL31_BLOB} ROCKCHIP_TPL=${RKBIN_DIR}/${DDR_BLOB};;u-boot-rockchip.bin u-boot-rockchip-spi.bin"
	unset uboot_custom_postprocess write_uboot_platform write_uboot_platform_mtd # disable stuff from rockchip64_common; we're using binman here which does all the work already

	# Just use the binman-provided u-boot-rockchip.bin, which is ready-to-go
	function write_uboot_platform() {
		dd "if=$1/u-boot-rockchip.bin" "of=$2" bs=32k seek=1 conv=notrunc status=none
	}

	function write_uboot_platform_mtd() {
		flashcp -v -p "$1/u-boot-rockchip-spi.bin" /dev/mtd0
	}
}


# Mainline U-Boot for current kernel
function post_family_config_branch_current__orangepi5plus_use_mainline_uboot() {
        display_alert "$BOARD" "Mainline U-Boot overrides for $BOARD - $BRANCH" "info"

        declare -g BOOTCONFIG="orangepi-5-plus-rk3588_defconfig"      # override the default for the board/family
        declare -g BOOTDELAY=1                                        # Wait for UART interrupt to enter UMS/RockUSB mode etc
        declare -g BOOTSOURCE="https://github.com/u-boot/u-boot.git"  # We ❤️ mainline U-Boot
        declare -g BOOTBRANCH="tag:v2024.07-rc4"
        declare -g BOOTPATCHDIR="v2024.07/board_${BOARD}"
        declare -g BOOTDIR="u-boot-${BOARD}"                          # do not share u-boot directory
        declare -g UBOOT_TARGET_MAP="BL31=${RKBIN_DIR}/${BL31_BLOB} ROCKCHIP_TPL=${RKBIN_DIR}/${DDR_BLOB};;u-boot-rockchip.bin u-boot-rockchip-spi.bin"
        unset uboot_custom_postprocess write_uboot_platform write_uboot_platform_mtd # disable stuff from rockchip64_common; we're using binman here which does all the work already

        # Just use the binman-provided u-boot-rockchip.bin, which is ready-to-go
        function write_uboot_platform() {
                dd "if=$1/u-boot-rockchip.bin" "of=$2" bs=32k seek=1 conv=notrunc status=none
        }

        function write_uboot_platform_mtd() {
                flashcp -v -p "$1/u-boot-rockchip-spi.bin" /dev/mtd0
        }
}

function post_family_tweaks__orangepi5-plus-kali_udev_network_interfaces() {
        display_alert "$BOARD" "Renaming interfaces WAN LAN" "info"

	mkdir -p $SDCARD/etc/udev/rules.d/
	cat <<- EOF > "${SDCARD}/etc/udev/rules.d/70-persistent-net.rules"
		SUBSYSTEM=="net", ACTION=="add", KERNELS=="0004:41:00.0", NAME:="lan"
		SUBSYSTEM=="net", ACTION=="add", KERNELS=="0003:31:00.0", NAME:="wan"
	EOF
}

